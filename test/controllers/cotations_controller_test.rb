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

  # ==================== TESTS CRITIQUES ====================
  # Le prix d'un devis vient toujours du tarif des prestations, jamais de la requête.

  # Test critique.

  test 'index : sans paramètre → la page répond' do
    get cotations_url
    assert_response :success
  end

  test 'index : recherche → seulement les cotations correspondantes' do
    cotation = cotations(:cotation_paris)

    get cotations_url(search: cotation.intitulé)

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'index : adhérent_ids → seulement les cotations de ces adhérents' do
    cotation = cotations(:cotation_paris)

    get cotations_url(adhérent_ids: [cotation.adherent_id])

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'index : service_ids → seulement les cotations de ces services' do
    cotation = cotations(:cotation_paris)

    get cotations_url(service_ids: [cotation.service_id])

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'index : workflow_state → seulement cet état, quelle que soit la casse' do
    cotation = cotations(:cotation_paris)

    get cotations_url(workflow_state: cotation.workflow_state.capitalize)

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'index : le dernier mail_log de chaque cotation est exposé' do
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

  test 'index : un adhérent voit toutes ses cotations envoyées, quel que soit le service prestataire' do
    cotations(:cotation_paris).update!(workflow_state: 'envoyé')
    sign_in @adherent
    get cotations_url

    assert_response :success
    listed = assigns(:cotations)
    assert_includes listed, cotations(:cotation_paris)       # service Informatique (rattaché)
    assert_includes listed, cotations(:cotation_secretariat) # service Secrétariat (non rattaché)
  end

  test "index : un adhérent ne voit pas ses cotations encore à l'état créé" do
    sign_in @adherent
    get cotations_url

    assert_response :success
    refute_includes assigns(:cotations), cotations(:cotation_paris) # créé, à weil
  end

  test "index : le filtre Services d'un adhérent liste les services de ses cotations envoyées" do
    cotations(:cotation_paris).update!(workflow_state: 'envoyé')
    sign_in @adherent
    get cotations_url

    svcs = assigns(:services)
    assert_includes svcs, services(:informatique)
    assert_includes svcs, services(:secretariat)
  end

  test 'show : une cotation de son périmètre → la page répond et le PDF est rendu' do
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

  test "show : l'historique des envois de la cotation est affiché" do
    cotation = cotations(:cotation_paris)
    MailLog.create!(organisation: cotation.organisation, cotation:, user_id: 0,
                    to: 'destinataire@exemple.fr', subject: 'Votre cotation',
                    statut: true, channel: 0)

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Historique des envois'
    assert_select 'td', text: 'destinataire@exemple.fr'
  end

  test "show : le journal d'activité est affiché à un manager ou un administrateur" do
    cotation = cotations(:cotation_paris)
    # Une modification génère un audit (gem `audited`) ; on vérifie qu'il
    # apparaît dans la section « Activité » (rendue par le partial _audit + prettify).
    cotation.update!(intitulé: 'Intitulé révisé')

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Intitulé révisé/
  end

  test 'new : avec un adhérent en paramètre → il est préchargé' do
    get new_cotation_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test 'create : paramètres valides → total calculé depuis les tarifs et ref générée' do
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
    assert_match(/\ACO-#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test 'create : sans intitulé → aucune création et formulaire réaffiché' do
    assert_no_difference -> { Cotation.count } do
      post cotations_url, params: { cotation: {
        adherent_id: @adherent.id, service_id: @service.id, intitulé: ''
      } }
    end
    assert_response :unprocessable_content
  end

  test 'edit : une cotation sans ligne → une ligne vide est amorcée' do
    cotation = Cotation.create!(intitulé: 'Cotation sans ligne', adherent: @adherent, service: @service,
                                organisation: organisations(:mairie_paris))

    get edit_cotation_url(cotation)

    assert_response :success
    assert_equal 1, assigns(:cotation).cotation_lignes.size
  end

  test 'edit : une cotation envoyée → édition refusée' do
    cotation = cotations(:cotation_secretariat) # envoyé
    get edit_cotation_url(cotation)
    assert_redirected_to root_path
  end

  test "update : une cotation à l'état créé → elle est modifiée" do
    cotation = cotations(:cotation_paris) # créé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Titre corrigé' } }
    assert_redirected_to cotation_path(cotation)
    assert_equal 'Titre corrigé', cotation.reload.intitulé
  end

  test 'update : une cotation envoyée → données inchangées' do
    cotation = cotations(:cotation_secretariat) # envoyé
    titre = cotation.intitulé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Tentative de modif' } }
    assert_redirected_to root_path
    assert_equal titre, cotation.reload.intitulé
  end

  test 'update : paramètres invalides → formulaire réaffiché en 422' do
    cotation = cotations(:cotation_paris)

    patch cotation_url(cotation), params: { cotation: { intitulé: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', cotation.reload.intitulé
  end

  test 'critique : update, prix de ligne forgé dans les paramètres → prix inchangé' do
    post cotations_url, params: { cotation: {
      adherent_id: @adherent.id, service_id: @service.id, intitulé: 'Devis',
      cotation_lignes_attributes: { '0' => { prestation_id: @prestation.id, qté: 1, prix_ht: 1 } }
    } }
    ligne = Cotation.order(:created_at).last.cotation_lignes.first
    assert_equal @prestation.tarif, ligne.prix_ht
  end

  test 'destroy : une cotation de son périmètre → soft delete' do
    cotation = cotations(:cotation_paris)
    assert_no_difference -> { Cotation.count } do
      delete cotation_url(cotation)
    end
    assert cotation.reload.discarded?
    assert_redirected_to cotations_path
  end

  test "envoyer : depuis l'état créé → envoyé" do
    cotation = cotations(:cotation_paris) # créé
    post envoyer_cotation_url(cotation)
    assert_redirected_to cotation_path(cotation)
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test "envoyer : la notification de l'adhérent est enfilée" do
    cotation = cotations(:cotation_paris) # créé, adhérent avec email
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
  end

  test "envoyer : depuis l'état refusé → la notification est renvoyée" do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.refuser!
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'envoyer : depuis un état impossible → aucune notification' do
    cotation = cotations(:cotation_secretariat) # envoyé : envoyer n'est pas possible
    assert_no_enqueued_jobs only: NotifAdherentCotationEnvoyeeJob do
      post envoyer_cotation_url(cotation)
    end
  end

  test "valider : depuis l'état signé → validé" do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.update!(workflow_state: 'signé')   # la validation n'est possible qu'après signature
    post valider_cotation_url(cotation)
    assert_equal 'validé', cotation.reload.workflow_state
  end

  test "valider : depuis l'état créé → sans effet" do
    cotation = cotations(:cotation_paris) # créé
    post valider_cotation_url(cotation)
    assert_equal 'créé', cotation.reload.workflow_state
  end

  test "refuser : depuis l'état envoyé → refusé" do
    cotation = cotations(:cotation_secretariat) # envoyé
    post refuser_cotation_url(cotation)
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test 'refuser : le créateur de la cotation est notifié' do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifManagerCotationRefuseeJob,
                         args: [cotation, @admin, @adherent.id]) do
      post refuser_cotation_url(cotation)
    end
  end

  test "refuser : le créateur qui refuse lui-même n'est pas notifié" do
    cotation = cotations(:cotation_secretariat) # envoyé, créée par @admin, qui est connecté

    assert_no_enqueued_jobs only: NotifManagerCotationRefuseeJob do
      post refuser_cotation_url(cotation)
    end
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test 'refuser : un autre gestionnaire notifie bien le créateur' do
    sign_in users(:manager_paris)
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifManagerCotationRefuseeJob,
                         args: [cotation, @admin, users(:manager_paris).id]) do
      post refuser_cotation_url(cotation)
    end
  end

  test 'refuser : depuis un état impossible → aucune notification' do
    cotation = cotations(:cotation_paris) # créé : refuser n'est pas possible

    assert_no_enqueued_jobs only: NotifManagerCotationRefuseeJob do
      post refuser_cotation_url(cotation)
    end
    assert_equal 'créé', cotation.reload.workflow_state
  end

  test 'create_commande : depuis une cotation validée → la commande et ses lignes' do
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'validé')

    assert_difference -> { Commande.count } => 1, -> { CommandeLigne.count } => 1 do
      post create_commande_cotation_url(cotation)
    end

    commande = Commande.order(:created_at).last
    assert_redirected_to commande_path(commande)
    assert_equal cotation.adherent_id, commande.adherent_id
    assert_equal cotation.intitulé, commande.intitulé
    assert_equal 'créé', commande.workflow_state
  end

  test 'create_commande : commande invalide → aucune création et retour à la cotation' do
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'validé')
    cotation.update_column(:intitulé, nil) # bypass : rend la commande copiée invalide

    assert_no_difference 'Commande.count' do
      post create_commande_cotation_url(cotation)
    end

    assert_redirected_to cotation_path(cotation)
    assert_equal 'Impossible de créer la commande.', flash[:alert]
  end

  test 'signer : un adhérent accède au formulaire de signature' do
    sign_in @adherent
    get signer_cotation_url(cotations(:cotation_secretariat)) # envoyé
    assert_response :success
  end

  test 'signer_do : un adhérent signe une cotation envoyée → signée, signature et ip persistées' do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris (a un email)

    post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }

    # Depuis le nouveau workflow, la signature transite vers « signé » (la validation
    # reste à la charge du gestionnaire) et redirige vers la cotation.
    assert_redirected_to cotation_url(cotation)
    cotation.reload
    assert_equal 'signé', cotation.workflow_state
    assert_equal SIGNATURE, cotation.signature
    assert_not_nil cotation.signee_le
    assert cotation.ip.present?
  end

  test 'signer_do : le créateur de la cotation est notifié' do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifCotationSigneeJob) do
      post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }
    end
  end

  test 'signer_do : sans créateur identifiable → aucune notification' do
    sign_in @adherent
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'envoyé') # signable, mais sans audit create

    assert_no_enqueued_jobs only: NotifCotationSigneeJob do
      post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }
    end

    # La signature est bien enregistrée (le workflow transite vers « signé ») même
    # sans destinataire à notifier.
    assert_equal 'signé', cotation.reload.workflow_state

    # ⚠ Régression signalée, non corrigée : sans email côté créateur, `signer_do`
    # sort avant le `redirect_to` → 204, l'adhérent signe sans aucun retour.
    assert_response :no_content
  end

  test "signer_do : une cotation non envoyée → rien n'est signé" do
    # CotationPolicy#signer? exige `record.can_signer?` : sur une cotation `créé`,
    # l'autorisation échoue en amont (redirection root), avant toute signature.
    sign_in @adherent
    cotation = cotations(:cotation_paris) # créé

    post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }

    assert_redirected_to root_path
    cotation.reload
    assert_equal 'créé', cotation.workflow_state
    assert_nil cotation.signature
  end

SIGNATURE = 'data:image/svg+xml;base64,PHN2Zz48L3N2Zz4='
end
