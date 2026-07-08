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
    assert_match(/\ACO-#{Date.current.year}-\d+\z/, cotation.ref)
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
    post envoyer_cotation_url(cotation)
    assert_redirected_to cotation_path(cotation)
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'envoyer : déclenche la notification de l\'adhérent' do
    cotation = cotations(:cotation_paris) # créé, adhérent avec email
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
  end

  test 'renvoyer depuis refusé : re-déclenche la notification' do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.refuser!
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'une transition impossible ne déclenche aucune notification' do
    cotation = cotations(:cotation_secretariat) # envoyé : envoyer n'est pas possible
    assert_no_enqueued_jobs only: NotifAdherentCotationEnvoyeeJob do
      post envoyer_cotation_url(cotation)
    end
  end

  test 'valider : signé -> validé' do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.update!(workflow_state: 'signé')   # la validation n'est possible qu'après signature
    post valider_cotation_url(cotation)
    assert_equal 'validé', cotation.reload.workflow_state
  end

  test 'refuser : envoyé -> refusé' do
    cotation = cotations(:cotation_secretariat) # envoyé
    post refuser_cotation_url(cotation)
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test 'valider est sans effet sur une cotation en créé (transition impossible)' do
    cotation = cotations(:cotation_paris) # créé
    post valider_cotation_url(cotation)
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

  test "le show affiche l'historique des envois (mail_logs de la cotation)" do
    cotation = cotations(:cotation_paris)
    MailLog.create!(organisation: cotation.organisation, cotation:, user_id: 0,
                    to: 'destinataire@exemple.fr', subject: 'Votre cotation',
                    statut: true, channel: 0)

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Historique des envois'
    assert_select 'td', text: 'destinataire@exemple.fr'
  end

  test "le show affiche le journal d'activité (audits) pour un manager/admin" do
    cotation = cotations(:cotation_paris)
    # Une modification génère un audit (gem `audited`) ; on vérifie qu'il
    # apparaît dans la section « Activité » (rendue par le partial _audit + prettify).
    cotation.update!(intitulé: 'Intitulé révisé')

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Intitulé révisé/
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

  # --- Signature (signer / signer_do) ---
  # La policy réserve ces actions aux adhérents (CotationPolicy#signer? => adhérent?).
  SIGNATURE = 'data:image/svg+xml;base64,PHN2Zz48L3N2Zz4='

  test 'signer : un adhérent accède au formulaire de signature' do
    sign_in @adherent
    get signer_cotation_url(cotations(:cotation_secretariat)) # envoyé
    assert_response :success
  end

  test "signer : un non-adhérent (admin) n'est pas autorisé" do
    # @admin est déjà connecté (setup)
    get signer_cotation_url(cotations(:cotation_secretariat))
    assert_redirected_to root_path
  end

  test 'signer_do : un adhérent signe une cotation envoyée -> signée + signature/ip/date persistées' do
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

  test 'signer_do : la signature notifie le créateur de la cotation (via l\'audit de création)' do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifCotationSigneeJob) do
      post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }
    end
  end

  test 'signer_do : sans créateur identifiable (aucun audit), aucune notification n\'est enqueue' do
    sign_in @adherent
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'envoyé') # signable, mais sans audit create

    assert_no_enqueued_jobs only: NotifCotationSigneeJob do
      post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }
    end

    # La signature est bien enregistrée (le workflow transite vers « signé ») même
    # sans destinataire à notifier.
    assert_equal 'signé', cotation.reload.workflow_state

    # ⚠ RÉGRESSION signalée (non corrigée) : `signer_do` exécute
    # `return if creator&.email.blank?` AVANT le `redirect_to`. Quand le créateur
    # n'a pas d'email (ou n'est pas identifiable), l'action ne rend rien → 204 No
    # Content. Via Turbo, l'adhérent signe sans aucun retour visuel (ni redirection
    # ni flash). Avant le refactor, `redirect_to root_path` s'exécutait toujours.
    # Correctif proposé : sortir le `redirect_to` de la garde (p. ex. remettre la
    # notification dans une méthode privée dédiée, comme `notify_adherent_cotation_envoyee`).
    assert_response :no_content
  end

  test "signer_do : refusé par la policy si la cotation n'est pas envoyée (état créé) : rien n'est signé" do
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

  test "signer_do : un non-adhérent n'est pas autorisé et ne signe pas" do
    cotation = cotations(:cotation_secretariat) # envoyé ; @admin connecté

    post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }

    assert_redirected_to root_path
    cotation.reload
    assert_nil cotation.signature
    assert_equal 'envoyé', cotation.workflow_state
  end

  test "signer_do : un adhérent ne peut pas signer la cotation d'un autre adhérent" do
    sign_in @adherent # weil
    autre = cotations(:cotation_marseille) # adhérent: michael_jackson
    autre.update!(workflow_state: 'envoyé') # envoyée, mais pas à weil

    post signer_do_cotation_url(autre), params: { cotation: { signature: SIGNATURE } }

    assert_redirected_to root_path
    autre.reload
    assert_nil autre.signature
    assert_equal 'envoyé', autre.workflow_state
  end

  # --- Index côté adhérent (voit TOUTES ses cotations, tous services confondus) ---
  # weil est rattaché au seul service Informatique mais possède une cotation sur
  # Secrétariat : l'ancien filtre `.where(service: current_user.services)` la masquait.

  test 'un adhérent voit toutes ses cotations, quel que soit le service prestataire' do
    sign_in @adherent
    get cotations_url

    assert_response :success
    listed = assigns(:cotations)
    assert_includes listed, cotations(:cotation_paris)       # service Informatique (rattaché)
    assert_includes listed, cotations(:cotation_secretariat) # service Secrétariat (non rattaché)
  end

  test "le filtre Services d'un adhérent liste les services de ses cotations" do
    sign_in @adherent
    get cotations_url

    svcs = assigns(:services)
    assert_includes svcs, services(:informatique)
    assert_includes svcs, services(:secretariat)
  end

  # --- Création de commande depuis une cotation (create_commande) ---
  # CotationPolicy#create_commande? exige manage? ET une cotation à l'état « validé ».

  test 'create_commande : depuis une cotation validée, crée la commande avec ses lignes et redirige' do
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

  test 'create_commande : commande invalide -> aucune création et retour à la cotation avec une alerte' do
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'validé')
    cotation.update_column(:intitulé, nil) # bypass : rend la commande copiée invalide

    assert_no_difference 'Commande.count' do
      post create_commande_cotation_url(cotation)
    end

    assert_redirected_to cotation_path(cotation)
    assert_equal 'Impossible de créer la commande.', flash[:alert]
  end
end
