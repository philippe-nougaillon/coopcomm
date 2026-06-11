# frozen_string_literal: true

require 'test_helper'

class CotationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @admin = users(:administrateur_paris)
    @adherent = users(:weil)
    @service = services(:informatique)
    @prestation = prestations(:nettoyage_bureaux)      # tarif 25.50
    sign_in @admin
  end

  test 'index accessible à un admin' do
    get cotations_url
    assert_response :success
  end

  test "l'index expose le dernier mail_log de chaque cotation" do
    cotation = cotations(:cotation_paris)
    organisation = cotation.organisation
    MailLog.create!(organisation:, cotation:, user_id: 0, to: 'a@b.fr',
                    subject: 'ancien', statut: false, channel: 0, created_at: 2.days.ago)
    dernier = MailLog.create!(organisation:, cotation:, user_id: 0, to: 'a@b.fr',
                              subject: 'récent', statut: true, etat: true, channel: 0, created_at: 1.hour.ago)

    get cotations_url

    assert_response :success
    last_mail_logs = assigns(:last_mail_logs)
    assert_equal dernier, last_mail_logs[cotation.id], 'doit retenir le mail_log le plus récent'
  end

  test 'new accessible avec adhérent prérempli' do
    get new_cotation_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test 'create : le total est calculé à partir du tarif des prestations et une ref est générée' do
    presta2 = prestations(:entretien_espaces_verts)    # tarif 30.00

    assert_difference -> { Cotation.count } => 1, -> { CotationLigne.count } => 2 do
      post cotations_url, params: { cotation: {
        adherent_id: @adherent.id,
        service_id: @service.id,
        intitulé: 'Devis test contrôleur',
        cotation_lignes_attributes: {
          '0' => { prestation_id: @prestation.id, qté: 3 },   # 25.50 × 3 = 76.50
          '1' => { prestation_id: presta2.id, qté: 2 }        # 30.00 × 2 = 60.00
        }
      } }
    end

    cotation = Cotation.order(:created_at).last
    assert_redirected_to cotation_path(cotation)
    assert_equal 136.5, cotation.total_ht.to_f
    assert_equal 'créé', cotation.workflow_state
    assert_match(/\A#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test "le prix d'une ligne ne peut pas être forcé via les paramètres" do
    post cotations_url, params: { cotation: {
      adherent_id: @adherent.id, service_id: @service.id, intitulé: 'Devis',
      cotation_lignes_attributes: { '0' => { prestation_id: @prestation.id, qté: 1, prix_ht: 1 } }
    } }
    ligne = Cotation.order(:created_at).last.cotation_lignes.first
    assert_equal @prestation.tarif, ligne.prix_ht
  end

  # --- Modification & verrou d'édition ---

  test 'update modifie une cotation modifiable (état créé)' do
    cotation = cotations(:cotation_paris) # créé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Titre corrigé' } }
    assert_redirected_to cotation_path(cotation)
    assert_equal 'Titre corrigé', cotation.reload.intitulé
  end

  test 'update interdit sur une cotation envoyée : données inchangées' do
    cotation = cotations(:cotation_secretariat) # envoyé
    titre = cotation.intitulé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Tentative de modif' } }
    assert_redirected_to root_path
    assert_equal titre, cotation.reload.intitulé
  end

  test 'edit interdit sur une cotation envoyée' do
    cotation = cotations(:cotation_secretariat) # envoyé
    get edit_cotation_url(cotation)
    assert_redirected_to root_path
  end

  # --- Workflow ---

  test 'envoyer : créé -> envoyé' do
    cotation = cotations(:cotation_paris) # créé
    get envoyer_cotation_url(cotation)
    assert_redirected_to cotation_path(cotation)
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'envoyer : déclenche la notification de l\'adhérent' do
    cotation = cotations(:cotation_paris) # créé, adhérent avec email
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      get envoyer_cotation_url(cotation)
    end
  end

  test 'renvoyer depuis refusé : re-déclenche la notification' do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.refuser!
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      get envoyer_cotation_url(cotation)
    end
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'une transition impossible ne déclenche aucune notification' do
    cotation = cotations(:cotation_secretariat) # envoyé : envoyer n'est pas possible
    assert_no_enqueued_jobs only: NotifAdherentCotationEnvoyeeJob do
      get envoyer_cotation_url(cotation)
    end
  end

  test 'valider : envoyé -> validé' do
    cotation = cotations(:cotation_secretariat) # envoyé
    get valider_cotation_url(cotation)
    assert_equal 'validé', cotation.reload.workflow_state
  end

  test 'refuser : envoyé -> refusé' do
    cotation = cotations(:cotation_secretariat) # envoyé
    get refuser_cotation_url(cotation)
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test 'valider est sans effet sur une cotation en créé (transition impossible)' do
    cotation = cotations(:cotation_paris) # créé
    get valider_cotation_url(cotation)
    assert_equal 'créé', cotation.reload.workflow_state
  end

  test 'show et génération du PDF' do
    cotation = cotations(:cotation_paris)
    get cotation_url(cotation)
    assert_response :success

    # L'URL se termine par le nom de fichier (et non "pdf.pdf")
    path = pdf_cotation_path(cotation, filename: cotation.pdf_filename)
    assert path.end_with?("/Cotation-#{cotation.ref}.pdf"), path

    get path
    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'destroy effectue un soft delete' do
    cotation = cotations(:cotation_paris)
    assert_no_difference -> { Cotation.count } do
      delete cotation_url(cotation)
    end
    assert cotation.reload.discarded?
    assert_redirected_to cotations_path
  end

  test "un agent n'est pas autorisé à voir l'index" do
    sign_in users(:agent_whatsapp)
    get cotations_url
    assert_redirected_to root_path
  end

  # --- Création invalide ---

  test 'create invalide (sans intitulé) : aucune cotation créée et formulaire re-rendu' do
    assert_no_difference -> { Cotation.count } do
      post cotations_url, params: { cotation: {
        adherent_id: @adherent.id, service_id: @service.id, intitulé: ''
      } }
    end
    assert_response :unprocessable_entity
  end
end
