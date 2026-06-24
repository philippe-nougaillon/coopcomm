# frozen_string_literal: true

require 'test_helper'

class InterventionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @intervention = interventions(:tonte_locaux)
    sign_in users(:hidalgo)
  end

  test 'should get index' do
    get interventions_url
    assert_response :success
  end

  # --- Pré-filtrage par service de l'index --------------------------------
  # administrateur_paris (org mairie_paris) a pour services service_paris /
  # informatique / technique. `comptabilite` est dans son organisation mais
  # PAS dans ses services → sert de témoin « hors périmètre personnel ».

  test 'index : un administrateur ne voit que ses services par défaut' do
    sign_in users(:administrateur_paris)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url

    assert_response :success
    assert_select "a[href=?]", intervention_path(hors_perimetre), { count: 0 },
                  'le service comptabilite (hors de ses services) ne doit pas apparaître par défaut'
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
  # weil est un adhérent du service `informatique`. En filtrant sur `service_paris`,
  # il ne doit rester proposé QUE pour un administrateur (liste complète).

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

  test 'should get index with export xls' do
    get users_url,  params: {
      format: :xls
    }

    assert_response :success
    assert_equal 'application/xls', response.content_type
  end

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

  test 'should show intervention' do
    get intervention_url(@intervention)
    assert_response :success
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

  # Pointage

  test 'pointer intervention repete doit créer une intervention' do
    # Le sign_in gère tout seul la déconnexion du premier sign_in dans le setup
    sign_in users(:martin_technique_paris)

    intervention = interventions(:intervention_repete)

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
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

    # 1er pointage (début de journée)
    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end

    # 2eme pointage (début de pause)
    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(intervention)
    end

    # 3eme pointage (fin de pause, reprise d'activité)
    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end

    # 4eme pointage (fin de journée)
    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(intervention)
    end

    expected_nb_intervention_filles = 2
    actual_nb_intervention_filles = Intervention.where(template_slug: intervention.slug).last(2).count

    assert_equal expected_nb_intervention_filles, actual_nb_intervention_filles
  end

  test 'pointer dont le save échoue ne renvoie pas 404 mais remonte l erreur' do
    agent = users(:martin_technique_paris)
    sign_in agent

    intervention = interventions(:intervention_repete)
    # L'agent est déjà affecté au modèle ; on lui ajoute une fenêtre planifiée.
    # L'intervention fille hérite de la même fenêtre et entre donc en conflit de
    # disponibilité avec son propre modèle → le save échoue (id nil).
    intervention.update_columns(début_prévue: DateTime.new(2026, 6, 1), fin_prévue: DateTime.new(2026, 6, 30))

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
  # Endpoint JSON alimentant la mise à jour dynamique de la liste des agents
  # en fonction du service sélectionné. hidalgo (manager) a accès aux services
  # service_paris / informatique / technique.

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
end
