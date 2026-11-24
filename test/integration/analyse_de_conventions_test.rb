# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'
require_relative '../support/faux_ovh'
require_relative '../support/fabrique_pdf'

class AnalyseDeConventionsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include FauxModele
  include FauxOvh
  include FabriquePdf

  setup do
    brancher_faux_modele
    sign_in users(:administrateur_paris)
  end

  teardown do
    debrancher_faux_ovh
    debrancher_faux_modele
    fermer_pdf
  end

  test "En tant qu'administrateur, je veux déposer une convention depuis la liste des conventions et la retrouver dans la file d'analyse" do
    get conventions_url
    assert_dom 'a[href=?]', analyses_conventions_path, text: /Importation des conventions/

    get analyses_conventions_url
    assert_response :success
    assert_dom 'a[href=?]', conventions_path, text: /Retour à la liste des conventions/

    post analyses_conventions_url, params: { convention: { document: [fixture_file_upload('exemple.pdf', 'application/pdf')] } }
    follow_redirect!

    assert_dom "tr##{dom_id(Convention.order(:id).last)}", text: /exemple\.pdf.*#{users(:administrateur_paris).nom_prénom.strip}.*En attente/m
    assert_dom '#notification p', count: 1,
                                  text: "1 document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué."
  end

  test "En tant qu'administrateur, je veux valider la convention qu'une analyse a lue et la retrouver dans la liste des conventions" do
    stub_reponse_du_modele(reponse_du_modele)

    perform_enqueued_jobs only: AnalyserConventionJob do
      post analyses_conventions_url, params: { convention: { document: [fixture_file_upload(convention_de_weil, 'application/pdf')] } }
    end
    convention = Convention.order(:id).last
    follow_redirect!
    assert_dom "tr##{dom_id(convention)}", text: /Weil Ariel.*Technique.*350 h.*À valider/m

    get convention_url(convention)
    assert_dom 'form[action=?] button:not([disabled])', valider_convention_path(convention), text: 'Valider la convention'

    patch valider_convention_url(convention)
    follow_redirect!
    assert_dom '#notification p', text: 'Convention validée.'

    get conventions_url(adherent_id: users(:weil).id, service_id: services(:technique).id)
    assert_dom 'a[href=?]', convention_path(convention), text: /Weil Ariel/

    get analyses_conventions_url
    assert_dom "tr##{dom_id(convention)}", count: 0
  end

  test "En tant qu'administrateur, je veux créer l'adhérent qu'une analyse n'a pas trouvé, le choisir dans l'analyse, puis la valider" do
    analyse = conventions(:analyse_sans_adherent)

    get convention_url(analyse)
    assert_dom 'a[href=?]', admin_create_new_user_path(convention_id: analyse.slug), text: "Créer l'adhérent"

    get admin_create_new_user_url(convention_id: analyse.slug)
    assert_response :success
    assert_dom 'select[name=?] option[selected][value=?]', 'user[rôle]', 'adhérent'
    assert_dom 'input[name=?][value=?]', 'user[nom]', 'Beaumont'
    assert_dom 'select#user_service_ids option[selected]', count: 2

    post admin_create_new_user_do_url, params: { user: { rôle: 'adhérent', nom: 'Beaumont', email: 'mairie@beaumont.example.test',
                                                         address: 'Mairie, 8 Grande Rue, 54470 Beaumont', latitude: 48.85, longitude: 5.78,
                                                         service_ids: [services(:technique).id, services(:informatique).id] } }
    adherent = User.find_by(email: 'mairie@beaumont.example.test')
    assert_redirected_to user_url(adherent)

    get edit_convention_url(analyse)
    assert_dom 'select[name=?] option[value=?]', 'convention[user_id]', adherent.id.to_s

    patch convention_url(analyse), params: { convention: { user_id: adherent.id } }
    assert_redirected_to convention_url(analyse)

    patch valider_convention_url(analyse)
    assert_predicate analyse.reload, :validé?
    assert_equal adherent, analyse.user
  end

  test "En tant qu'administrateur d'une instance sans IA, je veux une liste des conventions sans bouton d'analyse" do
    ENV['LLM_HOST'] = nil

    get conventions_url

    assert_response :success
    assert_dom 'a[href=?]', analyses_conventions_path, count: 0
  end

  test "En tant qu'administrateur, je veux déposer une convention quand l'IA est en pause, la voir attendre l'IA, analysée dès qu'elle répond, puis l'IA remise en pause" do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    get analyses_conventions_url
    assert_dom '#etat_ia p', text: /L'IA est en pause/

    post analyses_conventions_url, params: { convention: { document: [fixture_file_upload(convention_de_weil, 'application/pdf')] } }
    perform_enqueued_jobs only: AnalyserConventionJob
    convention = Convention.order(:id).last
    assert_requested(:post, "#{INSTANCE_OVH}/unshelve", times: 1)
    follow_redirect!
    assert_dom "tr##{dom_id(convention)}", text: /En attente de l'IA/

    stub_etat_de_l_instance('ACTIVE')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_return(status: 200, body: '{"status":"ok"}')
    stub_reponse_du_modele(reponse_du_modele)
    perform_enqueued_jobs only: AnalyserConventionJob

    get analyses_conventions_url
    assert_dom "tr##{dom_id(convention)}", text: /Weil Ariel.*Technique.*350 h.*À valider/m

    perform_enqueued_jobs only: SurveillerIaJob
    assert_requested(:post, "#{INSTANCE_OVH}/shelve", times: 1)
  end

  test "En tant qu'administrateur, je veux que l'IA réveillée par mon dépôt soit remise en pause après l'analyse, même quand OVH n'a pas répondu à la demande de réveil" do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_timeout

    post analyses_conventions_url, params: { convention: { document: [fixture_file_upload(convention_de_weil, 'application/pdf')] } }
    perform_enqueued_jobs only: AnalyserConventionJob
    convention = Convention.order(:id).last
    follow_redirect!
    assert_dom "tr##{dom_id(convention)}", text: /En attente de l'IA/

    stub_etat_de_l_instance('ACTIVE')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_return(status: 200, body: '{"status":"ok"}')
    stub_reponse_du_modele(reponse_du_modele)
    perform_enqueued_jobs only: AnalyserConventionJob

    get analyses_conventions_url
    assert_dom "tr##{dom_id(convention)}", text: /Weil Ariel.*Technique.*350 h.*À valider/m

    perform_enqueued_jobs only: SurveillerIaJob
    assert_requested(:post, "#{INSTANCE_OVH}/shelve", times: 1)
  end

  private

  def convention_de_weil
    pdf_de_texte(['Entre la Communauté de Communes du Val Fictif et Ariel Weil, adhérent, il est convenu que le service ' \
                  'technique intervient pour un volume annuel de 350 heures. La convention prend effet le 1er janvier 2025.'])
  end

  def reponse_du_modele
    { 'adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'nom' => 'Ariel Weil', 'id' => users(:weil).id },
      'date_debut' => { 'extrait' => 'prend effet le 1er janvier 2025', 'valeur' => '2025-01-01' },
      'date_signature' => { 'extrait' => nil, 'valeur' => nil },
      'date_fin' => { 'extrait' => nil, 'valeur' => nil },
      'services' => [{ 'extrait' => 'un volume annuel de 350 heures', 'id' => services(:technique).id, 'heures' => 350 }],
      'resume' => 'Le service technique est mis à la disposition d’Ariel Weil pour 350 heures par an.' }.to_json
  end
end
