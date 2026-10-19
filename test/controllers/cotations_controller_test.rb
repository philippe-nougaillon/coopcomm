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

  # SVG vide encodé en base64 : la charge utile que le pad de signature envoie.
  SIGNATURE = 'data:image/svg+xml;base64,PHN2Zz48L3N2Zz4='

  test 'la liste des cotations est affichée avec succès' do
    get cotations_url
    assert_response :success
  end

  test 'la recherche dans la liste ne retourne que les cotations correspondantes' do
    cotation = cotations(:cotation_paris)

    get cotations_url(search: cotation.intitulé)

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'la liste filtrée par adhérents ne retourne que les cotations de ces adhérents' do
    cotation = cotations(:cotation_paris)

    get cotations_url(adhérent_ids: [cotation.adherent_id])

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'la liste filtrée par services ne retourne que les cotations de ces services' do
    cotation = cotations(:cotation_paris)

    get cotations_url(service_ids: [cotation.service_id])

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'la liste filtrée par état ne retourne que les cotations de cet état, quelle que soit la casse' do
    cotation = cotations(:cotation_paris)

    get cotations_url(workflow_state: cotation.workflow_state.humanize)

    assert_response :success
    assert_includes assigns(:cotations), cotation
  end

  test 'le dernier mail log de chaque cotation est exposé à la vue' do
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

  test 'une cotation est affichée avec succès et rendue en PDF sous son nom de fichier' do
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

  test "l'historique des envois d'une cotation est affiché" do
    cotation = cotations(:cotation_paris)
    MailLog.create!(organisation: cotation.organisation, cotation:, user_id: 0,
                    to: 'destinataire@exemple.fr', subject: 'Votre cotation',
                    statut: true, channel: 0)

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Historique des envois'
    assert_select 'td', text: 'destinataire@exemple.fr'
  end

  test "une modification de cotation apparaît dans son journal d'activité" do
    cotation = cotations(:cotation_paris)
    # Une modification génère un audit (gem `audited`) ; on vérifie qu'il
    # apparaît dans la section « Activité » (rendue par le partial _audit + prettify).
    cotation.update!(intitulé: 'Intitulé révisé')

    get cotation_url(cotation)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Intitulé révisé/
  end

  test 'le formulaire de création ouvert depuis un adhérent est affiché avec succès' do
    get new_cotation_url(adherent_id: @adherent.slug)
    assert_response :success
  end

  test 'une cotation est créée avec un total calculé depuis les tarifs et une référence générée' do
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

  test "une cotation sans intitulé n'est pas créée" do
    assert_no_difference -> { Cotation.count } do
      post cotations_url, params: { cotation: {
        adherent_id: @adherent.id, service_id: @service.id, intitulé: ''
      } }
    end
    assert_response :unprocessable_content
  end

  test "le formulaire de modification d'une cotation sans ligne amorce une ligne vide" do
    cotation = Cotation.create!(intitulé: 'Cotation sans ligne', adherent: @adherent, service: @service,
                                organisation: organisations(:mairie_paris))

    get edit_cotation_url(cotation)

    assert_response :success
    assert_equal 1, assigns(:cotation).cotation_lignes.size
  end

  test 'une cotation envoyée ne peut pas être ouverte en modification' do
    cotation = cotations(:cotation_secretariat) # envoyé
    get edit_cotation_url(cotation)
    assert_redirected_to root_path
  end

  test "une cotation à l'état créé peut être modifiée" do
    cotation = cotations(:cotation_paris) # créé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Titre corrigé' } }
    assert_redirected_to cotation_path(cotation)
    assert_equal 'Titre corrigé', cotation.reload.intitulé
  end

  test "une cotation envoyée n'est pas modifiée" do
    cotation = cotations(:cotation_secretariat) # envoyé
    titre = cotation.intitulé
    patch cotation_url(cotation), params: { cotation: { intitulé: 'Tentative de modif' } }
    assert_redirected_to root_path
    assert_equal titre, cotation.reload.intitulé
  end

  test "une cotation dont l'intitulé est vidé n'est pas modifiée" do
    cotation = cotations(:cotation_paris)

    patch cotation_url(cotation), params: { cotation: { intitulé: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', cotation.reload.intitulé
  end

  # ==================== TESTS CRITIQUES ====================

  # Le prix d'un devis vient toujours du tarif des prestations, jamais de la requête.
  test 'un prix de ligne forgé dans les paramètres est ignoré (critique)' do
    post cotations_url, params: { cotation: {
      adherent_id: @adherent.id, service_id: @service.id, intitulé: 'Devis',
      cotation_lignes_attributes: { '0' => { prestation_id: @prestation.id, qté: 1, prix_ht: 1 } }
    } }
    ligne = Cotation.order(:created_at).last.cotation_lignes.first
    assert_equal @prestation.tarif, ligne.prix_ht
  end

  # ==================== /TESTS CRITIQUES ====================

  test "une cotation est archivée lorsqu'elle est supprimée" do
    cotation = cotations(:cotation_paris)
    assert_no_difference -> { Cotation.count } do
      delete cotation_url(cotation)
    end
    assert cotation.reload.discarded?
    assert_redirected_to cotations_path
  end

  test "une cotation à l'état créé peut être envoyée" do
    cotation = cotations(:cotation_paris) # créé
    post envoyer_cotation_url(cotation)
    assert_redirected_to cotation_path(cotation)
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test "la notification de l'adhérent est enfilée lorsqu'une cotation est envoyée" do
    cotation = cotations(:cotation_paris) # créé, adhérent avec email
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
  end

  test "une cotation à l'état refusé peut être renvoyée et la notification de l'adhérent est enfilée de nouveau" do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.refuser!
    assert_enqueued_with(job: NotifAdherentCotationEnvoyeeJob) do
      post envoyer_cotation_url(cotation)
    end
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test "aucune notification n'est enfilée lorsqu'une cotation déjà envoyée est envoyée de nouveau" do
    cotation = cotations(:cotation_secretariat) # envoyé : envoyer n'est pas possible
    assert_no_enqueued_jobs only: NotifAdherentCotationEnvoyeeJob do
      post envoyer_cotation_url(cotation)
    end
  end

  test "une cotation à l'état signé peut être validée" do
    cotation = cotations(:cotation_secretariat) # envoyé
    cotation.update!(workflow_state: 'signé')   # la validation n'est possible qu'après signature
    post valider_cotation_url(cotation)
    assert_equal 'validé', cotation.reload.workflow_state
  end

  test "une cotation à l'état créé ne peut pas être validée" do
    cotation = cotations(:cotation_paris) # créé
    post valider_cotation_url(cotation)
    assert_equal 'créé', cotation.reload.workflow_state
  end

  test "une cotation à l'état envoyé peut être refusée" do
    cotation = cotations(:cotation_secretariat) # envoyé
    post refuser_cotation_url(cotation)
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test "le créateur d'une cotation est notifié lorsqu'un adhérent la refuse" do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifManagerCotationRefuseeJob,
                         args: [cotation, @admin, @adherent.id]) do
      post refuser_cotation_url(cotation)
    end
  end

  test "le créateur d'une cotation qui la refuse lui-même n'est pas notifié" do
    cotation = cotations(:cotation_secretariat) # envoyé, créée par @admin, qui est connecté

    assert_no_enqueued_jobs only: NotifManagerCotationRefuseeJob do
      post refuser_cotation_url(cotation)
    end
    assert_equal 'refusé', cotation.reload.workflow_state
  end

  test "le créateur d'une cotation est notifié lorsqu'un autre gestionnaire la refuse" do
    sign_in users(:manager_paris)
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifManagerCotationRefuseeJob,
                         args: [cotation, @admin, users(:manager_paris).id]) do
      post refuser_cotation_url(cotation)
    end
  end

  test "une cotation à l'état créé ne peut pas être refusée et aucune notification n'est enfilée" do
    cotation = cotations(:cotation_paris) # créé : refuser n'est pas possible

    assert_no_enqueued_jobs only: NotifManagerCotationRefuseeJob do
      post refuser_cotation_url(cotation)
    end
    assert_equal 'créé', cotation.reload.workflow_state
  end

  test 'une commande est créée avec ses lignes depuis une cotation validée' do
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

  test "aucune commande n'est créée lorsque la commande copiée depuis la cotation est invalide" do
    cotation = cotations(:cotation_paris)
    cotation.update!(workflow_state: 'validé')
    cotation.update_column(:intitulé, nil) # bypass : rend la commande copiée invalide

    assert_no_difference 'Commande.count' do
      post create_commande_cotation_url(cotation)
    end

    assert_redirected_to cotation_path(cotation)
    assert_equal 'Impossible de créer la commande.', flash[:alert]
  end

  test 'un adhérent accède au formulaire de signature' do
    sign_in @adherent
    get signer_cotation_url(cotations(:cotation_secretariat)) # envoyé
    assert_response :success
  end

  test "une cotation envoyée signée par un adhérent passe à l'état signé avec sa signature et son ip" do
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

  test "le créateur d'une cotation est notifié lorsqu'elle est signée" do
    sign_in @adherent
    cotation = cotations(:cotation_secretariat) # envoyé, audit create = administrateur_paris

    assert_enqueued_with(job: NotifCotationSigneeJob) do
      post signer_do_cotation_url(cotation), params: { cotation: { signature: SIGNATURE } }
    end
  end

  test "aucune notification n'est enfilée lorsqu'une cotation signée n'a pas de créateur identifiable" do
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

  test 'une cotation non envoyée ne peut pas être signée' do
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

end
