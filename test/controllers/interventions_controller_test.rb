# frozen_string_literal: true

require 'test_helper'

class InterventionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    sign_in users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Évaluations (note/avis) jamais visibles de l'agent noté, et validation ou
  # refus par l'adhérent.

  # Test critique — l'agent affecté ouvre SA propre intervention validée :
  # la page ne doit contenir ni l'avis ni la section Évaluation.
  test "critique : un agent ne voit pas son évaluation sur la page de son intervention" do
    agent = users(:john_wick)
    intervention = cree_intervention_evaluee(agent)
    sign_in agent

    get intervention_url(intervention)

    assert_response :success, "garde anti-faux-positif : l'agent doit accéder à la page"
    assert_no_match AVIS_SENTINELLE, response.body
  end

  # Test critique — même exigence sur l'export XLS de l'index, accessible à tous les
  # rôles.
  test "critique : l'export XLS d'un agent ne contient ni évaluation ni avis" do
    agent = users(:john_wick)
    intervention = cree_intervention_evaluee(agent)
    sign_in agent

    get interventions_url(format: :xls)

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    en_tetes = sheet.row(0).to_a
    assert_not_includes en_tetes, 'Évaluation'
    assert_not_includes en_tetes, 'Avis'
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, intervention.description,
                    "garde anti-faux-positif : l'intervention doit figurer dans l'export"
    assert_no_match AVIS_SENTINELLE, contenu
  end

  # Test critique — le manager, lui, garde les évaluations dans son export
  # (la correction B25 ne doit pas les faire disparaître pour tout le monde).
  test "critique : l'export XLS d'un manager contient les évaluations et avis" do
    get interventions_url(format: :xls) # hidalgo (manager) connecté par le setup

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    en_tetes = sheet.row(0).to_a
    assert_includes en_tetes, 'Évaluation'
    assert_includes en_tetes, 'Avis'
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, interventions(:tonte_locaux).avis
  end

  # Test critique — parcours quotidien : l'adhérent valide le travail terminé.
  test "critique : l'adhérent valide une intervention terminée" do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, "l'intervention doit passer à l'état validé"
  end

  # Test critique — parcours quotidien : l'adhérent refuse le travail terminé.
  test "critique : l'adhérent refuse une intervention terminée" do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.refusé?, "l'intervention doit passer à l'état refusé"
  end

  # Test critique — cas du quotidien (double-clic, retour navigateur, onglet en double) :
  # re-valider une intervention déjà validée.
  test "critique : re-valider une intervention déjà validée redirige avec un message (bug B3)" do
    skip 'Bug B3 : valider hors état → Workflow::NoTransitionAllowed non rescué (500) — à réactiver à la correction'
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)
    post valider_intervention_url(intervention)

    post valider_intervention_url(intervention) # 2e clic : plus en état terminé

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, 'le double-clic ne doit rien casser'
  end

  # Test critique — parcours quotidien de l'agent : terminer son intervention.
  test 'critique : terminer une intervention en conflit de disponibilité redirige au lieu de planter' do
    agent = users(:john_wick)
    intervention = cree_intervention_en_conflit(agent)
    sign_in agent

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert_match(/Conflit/, flash[:alert], "le motif du refus doit être affiché à l'utilisateur")
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # Même filet côté adhérent, sur les deux transitions qu'il déclenche.
  test 'critique : valider une intervention en conflit de disponibilité redirige au lieu de planter' do
    intervention = cree_intervention_en_conflit(users(:john_wick), workflow_state: 'terminé')
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  test 'critique : refuser une intervention en conflit de disponibilité redirige au lieu de planter' do
    intervention = cree_intervention_en_conflit(users(:john_wick), workflow_state: 'terminé')
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  # Test critique — bouton « Terminer » sans dates : l'agent est renvoyé au
  # formulaire, et l'enregistrement termine l'intervention.
  test 'critique : update avec la demande de terminaison termine l’intervention' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.terminé?
    assert_equal 'Intervention terminée', flash[:notice]
  end

  test 'critique : update avec la demande de terminaison est refusé sans date de fin' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: '', description: intervention.description }
    }

    assert_response :unprocessable_content
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
    assert_match(/Statut\s*:\s*Nouveau/, response.body, "le formulaire ne doit pas annoncer un état non enregistré")
  end

  # La demande de terminaison ne doit pas contourner la policy : un adhérent peut
  # modifier une intervention, mais jamais la terminer.
  test 'critique : un adhérent ne peut pas terminer une intervention via le paramètre' do
    intervention = interventions(:intervention_paris)
    sign_in users(:patrick_adherent_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  test 'update sans demande de terminaison laisse l’état inchangé' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?
  end

  # Garde anti-faux-positif : sans conflit, la transition passe toujours — le
  # filet ne doit pas bloquer le parcours nominal.
  test 'terminer une intervention saine reste possible' do
    agent = users(:john_wick)
    intervention = cree_intervention_en_conflit(agent, avec_conflit: false)
    sign_in agent

    post terminer_intervention_url(intervention)

    assert intervention.reload.terminé?
  end

  # Test critique — le temps facturé aux communes doit être enregistré quel que soit
  # le chemin de terminaison, sans qu'aucun formulaire ne le fournisse.
  test 'critique : terminer via le bouton enregistre le temps total et une pause à 0' do
    agent = users(:john_wick)
    intervention = cree_intervention_en_conflit(agent, avec_conflit: false)
    intervention.update_columns(temps_de_pause: nil, temps_total: nil)
    sign_in agent

    post terminer_intervention_url(intervention)

    intervention.reload
    assert intervention.terminé?
    assert_equal 0, intervention.temps_de_pause
    assert_in_delta 2.0, intervention.temps_total, 1e-6
  end

  test 'critique : le formulaire de terminaison rend la pause obligatoire' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause[required]'
  end

  # Test critique — le temps facturé se calcule par agent : une intervention
  # terminée sans agent vaut 0 heure et ne doit pas pouvoir être enregistrée.
  test 'critique : update avec la demande de terminaison est refusé sans agent' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description, agent_ids: [''] }
    }

    assert_response :unprocessable_content
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
    assert_match(/Au moins un agent est obligatoire/, response.body)
  end

  test 'critique : terminer via le bouton est refusé sans agent' do
    intervention = interventions(:intervention_paris)
    intervention.agents.destroy_all

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Au moins un agent est obligatoire/, flash[:alert])
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  test 'critique : le formulaire de terminaison rend les agents obligatoires' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'label[for=intervention_agent_ids] span.text-red-500'
  end

  test 'le formulaire ordinaire laisse les agents facultatifs' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_agent_ids'
    assert_select 'label[for=intervention_agent_ids] span.text-red-500', false
  end

  test 'le formulaire ordinaire laisse la pause facultative' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause'
    assert_select 'select#intervention_temps_de_pause[required]', false
  end

  # Sentinelle distinctive : détecter la fuite par la donnée, pas par le wording
  # des libellés, pour rester robuste aux refontes UX.
  AVIS_SENTINELLE = /AVIS-RESERVE-AUX-GESTIONNAIRES/

  # Une intervention validée, notée et commentée, dont +agent+ est l'agent affecté.
  def cree_intervention_evaluee(agent)
    Intervention.create!(
      description: 'Intervention évaluée du test critique',
      adherent: users(:weil),
      service: services(:comptabilite),
      agent_ids: [agent.id],
      début: DateTime.new(2024, 3, 11, 9, 0),
      fin: DateTime.new(2024, 3, 11, 11, 0),
      temps_de_pause: 0,
      temps_total: 2,
      workflow_state: 'validé',
      note: 1,
      avis: 'AVIS-RESERVE-AUX-GESTIONNAIRES : prestation décevante',
      slug: SecureRandom.uuid
    )
  end

  # Une intervention validée, saine, dans un service du manager connecté.
  def cree_intervention_validee
    Intervention.create!(
      description: 'Intervention validée du test',
      adherent: users(:weil),
      service: services(:technique),
      agent_ids: [users(:john_wick).id],
      début: DateTime.new(2024, 5, 6, 9, 0),
      fin: DateTime.new(2024, 5, 6, 11, 0),
      temps_de_pause: 0,
      workflow_state: 'validé',
      slug: SecureRandom.uuid
    )
  end

  # Une intervention de +agent+ que la règle de disponibilité #357 rend invalide : une
  # SECONDE intervention du même agent recouvre sa plage.
  def cree_intervention_en_conflit(agent, workflow_state: 'nouveau', avec_conflit: true)
    intervention = Intervention.create!(
      description: 'Intervention à terminer', adherent: users(:weil), service: services(:comptabilite),
      agent_ids: [agent.id], début: DateTime.new(2024, 3, 12, 9, 0), fin: DateTime.new(2024, 3, 12, 11, 0),
      temps_de_pause: 0, workflow_state: workflow_state, slug: SecureRandom.uuid
    )
    return intervention unless avec_conflit

    conflit = Intervention.new(
      description: 'Intervention qui recouvre la plage', adherent: users(:weil), service: services(:comptabilite),
      début: DateTime.new(2024, 3, 12, 8, 0), fin: DateTime.new(2024, 3, 12, 12, 0),
      temps_de_pause: 0, workflow_state: 'nouveau', slug: SecureRandom.uuid
    )
    conflit.save!(validate: false)
    AgentIntervention.create!(agent: agent, intervention: conflit)

    assert_not intervention.reload.valid?, 'garde : le montage doit bien rendre l’intervention invalide'
    intervention
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'should get index' do
    get interventions_url
    assert_response :success
  end

  # --- Pré-filtrage par service de l'index --------------------------------
  # administrateur_paris (org mairie_paris) a pour services service_paris / informatique /
  # technique.

  test 'index : un administrateur voit toute son organisation par défaut' do
    sign_in users(:administrateur_paris)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url

    assert_response :success
    assert_select "a[href=?]", intervention_path(hors_perimetre), { minimum: 1 },
                  'un admin voit par défaut toute son organisation, y compris hors de ses services'
  end

  test "index : un administrateur peut filtrer sur un autre service de son organisation" do
    sign_in users(:administrateur_paris)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_select "a[href=?]", intervention_path(hors_perimetre), { minimum: 1 },
                  "l'administrateur peut voir un service de son organisation hors de ses propres services"
  end

  test "index : le menu service propose toute l'organisation à un administrateur" do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
    assert_select "select[name='service[]'] option", { text: 'Comptabilité' },
                  'un service hors de ses services mais dans son organisation doit être proposé'
  end

  test "index : un manager ne peut pas forger un service hors de son périmètre" do
    # hidalgo (manager) est signé par le setup. service_marseille est hors org.
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    # Le param hors périmètre est ignoré → repli sur ses propres services
    assert_select "a[href=?]", intervention_path(hors_perimetre), { count: 0 },
                  'un manager ne doit pas voir un service hors de son périmètre via un param forgé'
    # …et le menu ne le lui propose pas non plus
    assert_select "select[name='service[]'] option", { text: 'Comptabilité', count: 0 }
  end

  # --- Affichage du filtre service selon le nombre de services ------------

  test 'index : le filtre service est masqué pour un utilisateur à un seul service' do
    sign_in users(:manager_marseille) # un seul service : service_marseille

    get interventions_url

    assert_response :success
    assert_select "select[name='service[]']", false,
                  'le filtre service doit être masqué quand le current_user n\'a qu\'un seul service'
  end

  test 'index : le filtre service reste visible pour un manager à plusieurs services' do
    # hidalgo (setup) a 3 services
    get interventions_url

    assert_response :success
    assert_select "select[name='service[]']"
  end

  test 'index : le filtre service reste visible pour un administrateur' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
    assert_select "select[name='service[]']"
  end

  # --- Liste des adhérents et filtre service ------------------------------
  # weil est un adhérent du service `informatique`. En filtrant sur `service_paris`, il ne
  # doit rester proposé QUE pour un administrateur (liste complète).

  test 'index : la liste des adhérents ne suit pas le filtre service pour un administrateur' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_select "select[name='adherent_id[]'] option[value=?]", users(:weil).id.to_s, { minimum: 1 },
                  "l'administrateur garde la liste complète des adhérents malgré le filtre service"
  end

  test 'index : la liste des adhérents suit le filtre service pour un manager' do
    # hidalgo (manager, setup) filtre sur service_paris : weil (informatique) sort de la liste
    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_select "select[name='adherent_id[]'] option[value=?]", users(:weil).id.to_s, { count: 0 },
                  'pour un manager, la liste des adhérents suit les services sélectionnés'
  end

  # NOTE : l'ancien test « should get index with export xls » appelait users_url (copier-
  # coller) — l'export des interventions n'était donc testé nulle part.

  test 'should get new' do
    get new_intervention_url
    assert_response :success
  end

  test 'should create intervention' do
    assert_difference('Intervention.count') do
      post interventions_url, params: {
        intervention: {
          début: @intervention.début,
          fin: @intervention.fin,
          temps_de_pause: @intervention.temps_de_pause,
          description: @intervention.description,
          workflow_state: @intervention.workflow_state,
          adherent_id: @intervention.adherent_id,
          temps_total: @intervention.temps_total,
          commentaires: @intervention.commentaires,
          note: @intervention.note,
          avis: @intervention.avis,
          repeter: @intervention.repeter,
          slug: SecureRandom.uuid,
          début_prévue: @intervention.début_prévue,
          fin_prévue: @intervention.fin_prévue,
          service_id: @intervention.service.id
        }
      }
    end

    assert_redirected_to intervention_url(Intervention.last)
  end

  test "un agent crée une intervention à postériori : elle est terminée d'emblée" do
    # john_wick n'a aucune intervention de fixture, donc jamais de conflit d'horaire
    # avec la plage créée ici.
    agent = users(:john_wick)
    sign_in agent

    # On se place à midi d'AUJOURD'HUI pour que "hours.ago" ne change jamais de jour ni d'année.
    travel_to Time.current.middle_of_day do
      assert_difference('Intervention.count') do
        post interventions_url, params: {
          intervention: {
            début: 2.hours.ago,
            fin: 1.hour.ago,
            description: 'Tonte saisie le soir',
            adherent_id: users(:patrick_adherent_paris).id,
            service_id: services(:technique).id,
            agent_ids: [agent.id],
            # Le formulaire agent soumet un workflow_state caché : il ne doit PAS
            # piloter l'état (mass assignment interdit). L'état terminé est forcé
            # côté serveur, même si le param vaut 'nouveau'.
            workflow_state: Intervention::NOUVEAU
          }
        }
      end
    end
    
    assert_equal Intervention::TERMINE, Intervention.last.workflow_state
  end

  test 'should show intervention' do
    get intervention_url(@intervention)
    assert_response :success
  end
  
  test 'should show intervention with location' do
    get intervention_url(interventions(:intervention_with_location))
    assert_response :success
    assert_select "#map"
  end

  test 'should get edit' do
    get edit_intervention_url(@intervention)
    assert_response :success
  end

  test 'should update intervention' do
    patch intervention_url(@intervention), params: {
      intervention: {
        début: @intervention.début,
        fin: @intervention.fin,
        temps_de_pause: @intervention.temps_de_pause,
        description: @intervention.description,
        workflow_state: @intervention.workflow_state,
        temps_total: @intervention.temps_total,
        commentaires: @intervention.commentaires,
        note: @intervention.note,
        avis: @intervention.avis,
        début_prévue: @intervention.début_prévue,
        fin_prévue: @intervention.fin_prévue,
        adherent: @intervention.adherent,
        service: @intervention.service
      }
    }
    assert_redirected_to intervention_url(@intervention)
  end

  test 'should destroy intervention without mouvements' do
    assert_difference('Intervention.count', -1) do
      delete intervention_url(interventions(:nouvelle_intervention))
    end

    assert_redirected_to interventions_url
  end

  test 'must not destroy intervention with mouvements' do
    assert_no_difference('Intervention.count') do
      delete intervention_url(@intervention)
    end

    assert_response :see_other # Redirection après erreur
  end

  test "should redirect to root if intervention doesn't exist" do
    get intervention_url('abcdefg')
    assert_redirected_to root_path
  end

  test 'should destroy photo with purge' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to @intervention
  end

  # --- Photos via le formulaire manager (dropzone) --------------------------
  # Régressions : la dropzone appelait `attachment.blob` (méthode de Attached::One) sur le
  # has_many_attached :photos → 500 sur edit dès qu'une photo était attachée.

  test 'edit affiche une intervention qui a déjà des photos' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    get edit_intervention_url(@intervention)

    assert_response :success
    # Sans `multiple`, le param redevient scalaire et la photo est perdue.
    assert_select "input[type=file][name='intervention[photos][]'][multiple]"
  end

  test 'update ajoute une photo soumise en tableau (forme émise par la dropzone multiple)' do
    assert_difference('@intervention.photos.count', 1) do
      patch intervention_url(@intervention), params: {
        intervention: { photos: [fixture_file_upload('exemple.png', 'image/png')] }
      }
    end
  end

  test 'update conserve les photos ré-émises en signed_id et ajoute la nouvelle' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    existante = @intervention.photos.first

    patch intervention_url(@intervention), params: {
      intervention: { photos: [existante.signed_id, fixture_file_upload('exemple.png', 'image/png')] }
    }

    assert_equal 2, @intervention.reload.photos.count
  end

  # --- Purge d'une photo -----------------------------------------------------
  # `purge?` = `show?` : même organisation ET (manager/admin OU adhérent de l'intervention
  # OU agent affecté).

  test "purge : un agent affecté à l'intervention peut supprimer une photo" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:bond)

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to @intervention
  end

  test 'purge : la photo est réellement supprimée (blob détruit et fichier effacé du stockage)' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    blob = @intervention.photos.first.blob
    sign_in users(:bond)

    assert_difference('ActiveStorage::Blob.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_not ActiveStorage::Blob.exists?(blob.id), 'le blob doit être détruit en base'
    assert_not ActiveStorage::Blob.service.exist?(blob.key),
               'le fichier doit être effacé du service de stockage (purge synchrone)'
  end

  test "purge : la suppression est tracée dans l'audit trail" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    photo_id = @intervention.photos.first.id

    assert_difference('@intervention.audits.count', 1) do
      delete purge_intervention_url(@intervention), params: { photo_id: photo_id }
    end

    assert_equal "Photo n°#{photo_id} supprimée", @intervention.audits.last.comment
  end

  test "purge : un agent NON affecté à l'intervention est refusé et la photo reste" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:martin_technique_paris)

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to root_path # user_not_authorized (pas de referrer en test)
  end

  test "purge : un agent d'une autre organisation est refusé" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:agent_marseille)

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to root_path
  end

  test "purge : l'adhérent de l'intervention peut supprimer une photo (épinglage : purge? = show?)" do
    # Comportement ACTUEL épinglé : la policy autorise aussi l'adhérent (client) à
    # supprimer les photos posées par les agents.
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:weil)

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end
  end

  test 'purge : photo_id inexistant → 404, rien ne se passe' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: { photo_id: 0 }
    end

    assert_response :not_found
  end

  test "purge : impossible de supprimer la photo d'une AUTRE intervention (find scopé)" do
    autre = interventions(:nouvelle_intervention)
    autre.photos.attach(file_fixture('exemple.png'))
    autre.save
    cible = autre.photos.first

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: { photo_id: cible.id }
    end

    assert_response :not_found
  end

  test 'purge : non connecté → redirigé vers la connexion' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_out users(:hidalgo)

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to new_user_session_path
  end

  test 'purge : la redirection après un DELETE Turbo est en 303 see_other' do
    # 303 après
    # toute soumission destructrice Turbo, comme le reste de l'app.
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    delete purge_intervention_url(@intervention), params: {
      photo_id: @intervention.photos.first.id
    }

    assert_response :see_other
  end

  # Pointage

  test 'pointer intervention repete doit créer une intervention' do
    # Le sign_in gère tout seul la déconnexion du premier sign_in dans le setup
    sign_in users(:martin_technique_paris)

    intervention = interventions(:intervention_repete)

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end
  end

  test 'pointer alors que l agent est absent aujourd hui est refusé avec le motif' do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0)

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(interventions(:intervention_repete))
    end

    assert_redirected_to intervention_path(interventions(:intervention_repete))
    assert_match 'Agent(s) indisponible(s)', flash[:alert]
  end

  test 'pointer l après-midi alors que l agent est absent le matin reste possible' do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0, matin: true)

    travel_to Time.current.change(hour: 14) do
      assert_difference('Intervention.count', 1) do
        get pointer_intervention_url(interventions(:intervention_repete))
      end
    end
  end

  test 'pointer intervention repete doit mettre fin à une intervention' do
    # Le sign_in gère tout seul la déconnexion du premier sign_in dans le setup
    sign_in users(:martin_technique_paris)
    intervention = interventions(:intervention_repete)

    # Pointage
    get pointer_intervention_url(intervention)

    intervention_créée = Intervention.find_by(template_slug: intervention.slug)

    assert_nil intervention_créée.fin

    # Repointage
    get pointer_intervention_url(intervention)

    intervention_créée.reload
    assert_not_nil intervention_créée
  end

  test 'pointer intervention pas repete ne doit pas créer une intervention' do
    intervention = interventions(:intervention_repete)
    intervention.repeter = false
    intervention.save

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(intervention)
    end
  end

  test 'pointer intervention repete doit créer une intervention fille par agent' do
    intervention = interventions(:intervention_repete)

    # Pointage avec le 1er agent
    sign_in users(:martin_technique_paris)
    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end

    # Pointage avec le 2eme agent
    sign_in users(:bond)
    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end

    expected_nb_intervention_filles = 2
    actual_nb_intervention_filles = Intervention.where(template_slug: intervention.slug).last(2).count

    assert_equal expected_nb_intervention_filles, actual_nb_intervention_filles
  end

test 'pointer intervention repete doit pouvoir créer plusieurs interventions dans la journée' do
    intervention = interventions(:intervention_repete)

    sign_in users(:martin_technique_paris)

    # Les pointages sont horodatés à la minute : on simule des heures distinctes (journée
    # passée fixe) pour reproduire un vrai parcours séquentiel.
    jour = Time.zone.local(2025, 1, 6)

    # 1er pointage (début de journée) -> Création (Clock in)
    assert_difference('Intervention.count', 1) do
      travel_to(jour + 8.hours) { get pointer_intervention_url(intervention) }
    end

    # 2eme pointage (début de pause) -> Clôture (Clock out)
    assert_no_difference('Intervention.count') do
      travel_to(jour + 12.hours) { get pointer_intervention_url(intervention) }
    end

    # 3eme pointage (fin de pause, reprise d'activité) -> Nouvelle Création (Clock in)
    assert_difference('Intervention.count', 1) do
      travel_to(jour + 13.hours) { get pointer_intervention_url(intervention) }
    end


    # 4eme pointage (fin de journée) -> Clôture (Clock out)
    assert_no_difference('Intervention.count') do
      travel_to(jour + 17.hours) { get pointer_intervention_url(intervention) }
    end

    # Il y a eu 2 créations (matin et après-midi), donc 2 interventions filles au total
    expected_nb_intervention_filles = 2
    actual_nb_intervention_filles = Intervention.where(template_slug: intervention.slug).last(2).count

    assert_equal expected_nb_intervention_filles, actual_nb_intervention_filles
  end

  test 'pointer dont le save échoue ne renvoie pas 404 mais remonte l erreur' do
    agent = users(:martin_technique_paris)
    sign_in agent

    intervention = interventions(:intervention_repete)
    # On force l'échec du save de la fille : sans adhérent, la validation de
    # présence échoue et le save renvoie false.
    intervention.update_columns(adherent_id: nil)

    assert_no_difference('Intervention.count') do
      assert_no_enqueued_jobs only: NotifMailAdherentInterventionPointageJob do
        get pointer_intervention_url(intervention)
      end
    end

    assert_response :redirect
    assert_match(/pointage n'a pas pu être enregistré/i, flash[:alert].to_s)
  end

  test "update location intervention doit ajouter la geolocalisation à l'intervention fille" do
    intervention = interventions(:intervention_repete)

    sign_in users(:martin_technique_paris)

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end

    intervention_fille = Intervention.where(template_slug: intervention.slug).last

    patch update_location_intervention_url(intervention_fille),
          params: { latitude: 48.8566, longitude: 2.3522 },
          as: :json

    intervention_fille.reload
    assert_not_nil intervention_fille.localisation, 'La localisation doit être mise à jour après pointage'
  end

  # --- update : branches de retour ---

  test 'update depuis le pointage statut redirige vers la home' do
    intervention = interventions(:intervention_fille)

    patch intervention_url(intervention),
          params: { intervention: { commentaires: 'Terminé côté agent' },
                    commit: 'Enregistrer le commentaire' }

    assert_redirected_to root_path
    assert_equal 'Terminé côté agent', intervention.reload.commentaires
  end

  test 'update invalide réaffiche le formulaire en 422' do
    patch intervention_url(@intervention), params: { intervention: { description: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @intervention.reload.description
  end

  test 'update invalide en JSON renvoie les erreurs' do
    patch intervention_url(@intervention),
          params: { intervention: { description: '' } },
          as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body['description'].to_s, 'doit être rempli'
  end

  # --- terminer / archiver : branches de refus ---

  test 'terminer une intervention déjà validée est refusé' do
    intervention = cree_intervention_validee

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Impossible de terminer/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  test 'archiver une intervention validée l\'archive' do
    intervention = cree_intervention_validee

    post archiver_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_equal 'archivé', intervention.reload.workflow_state
  end

  test 'archiver une intervention déjà archivée le signale' do
    intervention = cree_intervention_validee
    intervention.update_columns(workflow_state: 'archivé')

    post archiver_intervention_url(intervention)

    assert_match(/déjà archivée/i, flash[:alert].to_s)
  end

  test 'archiver une intervention qui n\'est pas au bon état est refusé' do
    intervention = interventions(:nouvelle_intervention)

    post archiver_intervention_url(intervention)

    assert_match(/ne peut pas se archiver/i, flash[:alert].to_s)
    assert_equal 'nouveau', intervention.reload.workflow_state
  end

  test 'archiver une intervention invalide est refusé avec son motif' do
    intervention = cree_intervention_en_conflit(users(:john_wick), workflow_state: 'validé')

    post archiver_intervention_url(intervention)

    assert_match(/n'est pas valide/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  # --- pointer : reprise d'activité ---

  # Branche défensive : une fille porte une `fin` tout en restant à l'état
  # « nouveau ». Le parcours normal les pose ensemble (`fin` + « terminé »), donc
  # `find_current_intervention` (qui ne cherche que « nouveau ») ne la retrouve
  # pas ; l'état est ici reconstitué à la main.
  test 'pointer sur une fille close mais restée nouveau enregistre une reprise d\'activité' do
    agent = users(:martin_technique_paris)
    sign_in agent
    modele = interventions(:intervention_repete)

    get pointer_intervention_url(modele)
    fille = Intervention.where(template_slug: modele.slug).last
    # Créneau déjà refermé et passé : la nouvelle fille démarrera « maintenant »
    # sans recouvrir celle-ci.
    fille.update_columns(début: 3.hours.ago, fin: 2.hours.ago, workflow_state: 'nouveau')

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(modele)
    end
    assert_match(/Reprise d'activité/i, flash[:notice].to_s)
  end

  test 'pointer sur une intervention qui n\'est pas un modèle est refusé' do
    intervention = interventions(:nouvelle_intervention) # bond y est agent affecté
    sign_in users(:bond)

    get pointer_intervention_url(intervention)

    assert_match(/n'est pas un modèle de pointage/i, flash[:alert].to_s)
  end

  # --- update_location : branche d'échec ---

  test 'update_location sur une intervention invalide renvoie les erreurs en 422' do
    sign_in users(:martin_technique_paris)
    get pointer_intervention_url(interventions(:intervention_repete))
    fille = Intervention.where(template_slug: interventions(:intervention_repete).slug).last
    fille.update_columns(adherent_id: nil) # rend le save suivant impossible

    patch update_location_intervention_url(fille),
          params: { latitude: 48.8566, longitude: 2.3522 },
          as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body['errors'].to_s, 'Adherent'
  end

  # --- Modèle de pointage : new / create ---

  test 'new_intervention_modele_pointage prépare une intervention répétée' do
    get new_intervention_modele_pointage_interventions_url

    assert_response :success
    assert assigns(:intervention).repeter
  end

  test 'create_intervention_modele_pointage crée un modèle à l\'état pointage activé' do
    assert_difference('Intervention.count', 1) do
      post create_intervention_modele_pointage_interventions_url,
           params: { intervention: { description: 'Modèle de pointage du test',
                                     adherent_id: users(:weil).id,
                                     service_id: services(:technique).id } }
    end

    modele = Intervention.order(:created_at).last
    assert_equal 'pointage activé', modele.workflow_state
    assert modele.repeter
    assert_redirected_to intervention_url(modele)
  end

  test 'create_intervention_modele_pointage invalide réaffiche le formulaire en 422' do
    assert_no_difference('Intervention.count') do
      post create_intervention_modele_pointage_interventions_url,
           params: { intervention: { description: '' } }
    end

    assert_response :unprocessable_content
  end

  test 'create_intervention_modele_pointage invalide en JSON renvoie les erreurs' do
    post create_intervention_modele_pointage_interventions_url,
         params: { intervention: { description: '' } },
         as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end

  test 'new (form manager) : liste des agents PLATE (sans optgroup) et câblée au service' do
    get new_intervention_url
    assert_response :success

    selecteur = "select[name='intervention[agent_ids][]']"
    # Plus aucun groupe dans la liste des agents
    assert_select "#{selecteur} optgroup", false, 'la liste des agents ne doit plus contenir de groupe'
    # Le select agents est la cible de mise à jour dynamique selon le service
    assert_select "#{selecteur}[data-dynamic-select-target='agents']"
    # Le select service déclenche le rechargement des agents
    assert_select "select[name='intervention[service_id]'][data-action*='dynamic-select#updateAgents']"
  end

  test 'should get new as agent (form_for_agents)' do
    sign_in users(:martin_technique_paris)
    get new_intervention_url
    assert_response :success
    # L'agent qui crée est obligatoire (data-mandatory) dans la liste plate
    assert_select "select[name='intervention[agent_ids][]'] option[data-mandatory='true']"
  end

  # --- GET agents_for_service ---------------------------------------------
  # Endpoint JSON alimentant la mise à jour dynamique de la liste des agents en fonction
  # du service sélectionné.

  test 'agents_for_service renvoie les agents du service en JSON' do
    get agents_for_service_interventions_url(service_id: services(:technique).id), as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_includes ids, users(:martin_technique_paris).id
    # Un adhérent ne doit jamais figurer dans la liste des agents
    assert_not_includes ids, users(:weil).id
    # Format attendu : {id, nom}
    agent = response.parsed_body.find { |a| a['id'] == users(:martin_technique_paris).id }
    assert_equal users(:martin_technique_paris).nom_prénom, agent['nom']
  end

  test 'agents_for_service borne le résultat au périmètre du current_user' do
    # service_marseille est hors du périmètre de hidalgo : on ne fuite pas ses agents
    get agents_for_service_interventions_url(service_id: services(:service_marseille).id), as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_not_includes ids, users(:agent_marseille).id
    # Service hors périmètre ⇒ repli sur tous les agents du current_user
    assert_includes ids, users(:martin_technique_paris).id
  end

  test 'agents_for_service sans service renvoie tous les agents du périmètre' do
    get agents_for_service_interventions_url, as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_includes ids, users(:martin_technique_paris).id
    assert_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  # --- Notification des managers à la création (after_create_commit du modèle,
  # --- exercé via le contrôleur : l'auteur vient de l'audit de création) ---

  test "création par un adhérent : enqueue la notification managers « nouvelle demande » avec les bons arguments" do
    adherent = users(:weil)
    sign_in adherent

    assert_difference('Intervention.count') do
      post interventions_url, params: { intervention: {
        description: 'Demande de nettoyage des locaux',
        adherent_id: adherent.id,
        service_id: services(:informatique).id,
        début_prévue: 2.days.from_now,
        fin_prévue: 2.days.from_now + 2.hours
      } }
    end

    intervention = Intervention.order(:id).last
    assert_enqueued_with(job: NotifManagersNewInterventionFromAdherentJob, args: [intervention, adherent])
  end

  test "création par un agent « à postériori » (terminée d'emblée) : enqueue la notification managers « réalisée »" do
    # john_wick et pas martin : cf. le test « à postériori » ci-dessus (B10).
    agent = users(:john_wick)
    sign_in agent

    # Milieu de journée : les "hours.ago" restent le même jour (cf. test à postériori ci-dessus).
    travel_to Time.current.middle_of_day do
      assert_difference('Intervention.count') do
        post interventions_url, params: { intervention: {
          début: 2.hours.ago,
          fin: 1.hour.ago,
          description: 'Tonte saisie le soir',
          adherent_id: users(:patrick_adherent_paris).id,
          service_id: services(:technique).id,
          agent_ids: [agent.id]
        } }
      end
    end

    intervention = Intervention.order(:id).last
    assert_equal Intervention::TERMINE, intervention.workflow_state
    assert_enqueued_with(job: NotifManagersInterventionDoneByAgentJob, args: [intervention, agent])
  end

  test "création par un manager : aucune notification managers n'est enqueue" do
    # hidalgo (manager) est connecté via le setup.
    assert_no_enqueued_jobs only: [NotifManagersNewInterventionFromAdherentJob,
                                   NotifManagersInterventionDoneByAgentJob] do
      assert_difference('Intervention.count') do
        post interventions_url, params: { intervention: {
          description: 'Intervention planifiée par le manager',
          adherent_id: users(:weil).id,
          service_id: services(:informatique).id,
          début_prévue: 2.days.from_now,
          fin_prévue: 2.days.from_now + 2.hours
        } }
      end
    end
  end

  # --- Affiche QRCode (show.pdf) : parcours 1, ce que l'agent scanne --------
  # L'affiche est générée/imprimée par un manager ou un admin ; l'agent, lui, ne fait que
  # la scanner (route GET `pointer`).

  test "show.pdf : un manager peut générer l'affiche QRCode du modèle de pointage" do
    # hidalgo (manager, service technique) est connecté via le setup.
    get intervention_url(interventions(:intervention_repete), format: :pdf)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'show.pdf : un agent ne peut pas générer l\'affiche QRCode' do
    sign_in users(:martin_technique_paris) # agent rattaché à l'intervention

    get intervention_url(interventions(:intervention_repete), format: :pdf)

    # Refus Pundit → redirection avec message d'alerte (cf. user_not_authorized)
    assert_response :redirect
    assert_match(/n'êtes pas autorisé/i, flash[:alert].to_s)
  end

  # --- pointage_statut : redirige vers le statut de la fille du pointeur ----

  test 'pointage_statut sur un modèle répété redirige vers la fille du pointeur' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)

    # On crée d'abord une fille (clock in) pour que la redirection ait une cible.
    get pointer_intervention_url(modele)

    get pointage_statut_intervention_url(modele)
    assert_response :redirect
  end

  # --- Parcours 2 : saisie a posteriori, chemins d'échec -------------------

  test "saisie a posteriori : fin antérieure au début est refusée (422)" do
    agent = users(:martin_technique_paris)
    sign_in agent

    travel_to Time.current.middle_of_day do
      assert_no_difference('Intervention.count') do
        post interventions_url, params: { intervention: {
          début: 1.hour.ago,
          fin: 2.hours.ago, # fin AVANT le début → schedules_must_make_sense
          description: 'Saisie incohérente',
          adherent_id: users(:patrick_adherent_paris).id,
          service_id: services(:technique).id,
          agent_ids: [agent.id]
        } }
      end
    end

    assert_response :unprocessable_content
  end

  test "saisie a posteriori : des dates dans le futur sont refusées (422)" do
    agent = users(:martin_technique_paris)
    sign_in agent

    assert_no_difference('Intervention.count') do
      post interventions_url, params: { intervention: {
        début: 1.hour.from_now,
        fin: 2.hours.from_now, # cohérentes entre elles mais dans le futur
        description: 'Saisie dans le futur',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        agent_ids: [agent.id]
      } }
    end

    assert_response :unprocessable_content
  end

  # --- Parcours 1 : le second scan clôture la fille (état terminé + fin) ----

  test 'pointer : le second scan termine la fille (état terminé, fin renseignée)' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)

    get pointer_intervention_url(modele) # 1er scan : clock in
    fille = Intervention.find_by(template_slug: modele.slug)
    assert_nil fille.fin, 'la fille est ouverte après le premier scan'

    get pointer_intervention_url(modele) # 2e scan : clock out

    fille.reload
    assert_equal Intervention::TERMINE, fille.workflow_state
    assert_not_nil fille.fin, 'le second scan renseigne la fin'
  end

  # --- L'adhérent d'une fille de pointage est figé pour l'agent --------------

  test "un agent ne peut pas changer l'adhérent d'une fille de pointage" do
    agent = users(:martin_technique_paris)
    sign_in agent
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)
    adherent_initial = fille.adherent

    patch intervention_url(fille), params: {
      intervention: { adherent_id: users(:patrick_adherent_paris).id, description: 'Pointage modifié' }
    }

    fille.reload
    assert_equal adherent_initial, fille.adherent
    assert_equal 'Pointage modifié', fille.description, 'le reste de la modification doit passer'
  end

  test "le formulaire d'édition d'une fille de pointage n'offre pas de choix d'adhérent" do
    agent = users(:martin_technique_paris)
    sign_in agent
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    get edit_intervention_url(fille)

    assert_response :success
    assert_select 'select#intervention_adherent_id', false
    assert_select 'input#intervention_adherent_id[disabled]'
  end

  test "un agent change toujours l'adhérent d'une intervention hors pointage" do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    sign_in agent

    patch intervention_url(intervention), params: {
      intervention: { adherent_id: users(:patrick_adherent_paris).id, description: intervention.description }
    }

    assert_equal users(:patrick_adherent_paris), intervention.reload.adherent
  end

  test "un manager change toujours l'adhérent d'une fille de pointage" do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    sign_in users(:hidalgo)
    patch intervention_url(fille), params: {
      intervention: { adherent_id: users(:patrick_adherent_paris).id, description: fille.description }
    }

    assert_equal users(:patrick_adherent_paris), fille.reload.adherent
  end
end
