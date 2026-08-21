# frozen_string_literal: true

require 'test_helper'

class InterventionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    sign_in users(:hidalgo)
  end

  # Marqueur planté dans l'avis : il ne doit jamais atteindre l'agent noté.
  AVIS_SENTINELLE = /AVIS-RESERVE-AUX-GESTIONNAIRES/

  test 'set_intervention : un slug inconnu redirige sans planter' do
    get intervention_url('abcdefg')
    assert_redirected_to root_path
  end

  # ==================== TESTS CRITIQUES ====================

  test "index : un mot clé d'une autre organisation → aucune intervention (critique)" do
    sign_in users(:administrateur_paris)
    interventions(:nettoyage_port).update!(tag_list: 'secret-marseille')

    get interventions_url, params: { tags: ['secret-marseille'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test "index : liste des mots clés proposée → bornée à l'organisation (critique)" do
    sign_in users(:administrateur_paris)
    interventions(:nettoyage_port).update!(tag_list: 'secret-marseille')
    @intervention.update!(tag_list: 'urgence')

    get interventions_url

    assert_response :success
    noms = assigns(:intervention_tags).map(&:name)
    assert_includes noms, 'urgence'
    assert_not_includes noms, 'secret-marseille'
  end

  test "index : l'export XLS ne contient aucune intervention d'une autre organisation (critique)" do
    get interventions_url(format: :xls)

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, interventions(:tonte_locaux).description
    assert_not_includes contenu, interventions(:nettoyage_port).description
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'index : rendu nominal' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
  end

  test 'index : filtre service non soumis par un administrateur → toute son organisation' do
    sign_in users(:administrateur_paris)
    hors_perimetre = cree_intervention_hors_services

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), hors_perimetre
    assert_empty assigns(:selected_service_ids)
  end

  test 'index : filtre service sur un service de son organisation → seulement ce service' do
    sign_in users(:administrateur_paris)
    comptabilite = cree_intervention_hors_services

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_includes assigns(:interventions), comptabilite
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'index : filtre service non soumis par un manager → tous ses services' do
    technique = cree_intervention_index('Dans ses services', service: services(:technique))

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), technique
    assert_empty assigns(:selected_service_ids)
  end

  test 'index : filtre service forgé hors périmètre par un manager → repli sur ses services' do
    hors_perimetre = cree_intervention_hors_services

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_not_includes assigns(:interventions), hors_perimetre
  end

  test 'index : filtre service non soumis par un adhérent → toutes ses interventions' do
    weil = users(:weil)
    UserService.create!(user: weil, service: services(:technique))
    hors_services_membres = interventions(:tonte_locaux)
    hors_services_membres.update_columns(service_id: services(:informatique).id)
    sign_in weil

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_includes assigns(:interventions), hors_services_membres
  end

  test 'index : filtre service choisi par un adhérent → seulement ce service' do
    weil = users(:weil)
    UserService.create!(user: weil, service: services(:technique))
    autre_service = interventions(:tonte_locaux)
    autre_service.update_columns(service_id: services(:informatique).id)
    sign_in weil

    get interventions_url, params: { service: [services(:technique).id] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_not_includes assigns(:interventions), autre_service
  end

  test 'index : aucun filtre → les archivées sont exclues' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url

    assert_response :success
    assert_not_includes assigns(:interventions), archivee
  end

  test 'index : archives → seulement les archivées' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url(archives: '1')

    assert_response :success
    assert_includes assigns(:interventions), archivee
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'index : un statut → seulement les interventions de cet état' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { workflow_state: ['Nouveau'] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'index : plusieurs statuts → les interventions de ces états' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { workflow_state: %w[Nouveau Terminé] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_includes assigns(:interventions), interventions(:intervention_terminée)
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'index : statut vide → retombe sur le défaut, les non archivées' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url, params: { workflow_state: [''] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_not_includes assigns(:interventions), archivee
  end

  test 'index : recherche sur la description → les interventions correspondantes' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'Tonte locaux')

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'index : recherche sur les commentaires → les interventions correspondantes' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'bord des routes')

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'index : recherche sans correspondance → liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'zzz-aucune-correspondance-zzz')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'index : du et au → les interventions qui commencent dans l’intervalle' do
    sign_in users(:administrateur_paris)
    jour = @intervention.début.to_date

    get interventions_url(du: jour.to_s, au: jour.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'index : du seul → les interventions qui commencent ou finissent ce jour' do
    sign_in users(:administrateur_paris)

    get interventions_url(du: @intervention.début.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'index : au seul → les interventions qui finissent ce jour' do
    sign_in users(:administrateur_paris)

    get interventions_url(au: @intervention.fin.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'index : intervalle de dates hors période → liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url(du: '1900-01-01', au: '1900-01-02')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'index : adherent_id → seulement les interventions de cet adhérent' do
    sign_in users(:administrateur_paris)

    get interventions_url(adherent_id: users(:weil).id)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_adhérent)
  end

  test 'index : agent_ids → seulement les interventions de cet agent' do
    sign_in users(:administrateur_paris)

    get interventions_url(agent_ids: [users(:bond).id])

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_agent)
  end

  test 'index : tool_ids → seulement les interventions utilisant cet outil' do
    sign_in users(:administrateur_paris)

    get interventions_url(tool_ids: [tools(:tondeuse).id])

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_terminée)
  end

  test 'index : paramètre équipe forgé → ignoré, liste non restreinte' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin équipe')

    [['mairie'], 'mairie'].each do |valeur|
      get interventions_url(equipe: valeur)

      assert_response :success
      assert_includes assigns(:interventions), temoin
    end
  end

  test 'index : un mot clé → seulement les interventions qui le portent' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')
    ordinaire = cree_intervention_index('Ordinaire')

    get interventions_url, params: { tags: ['urgence'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente
    assert_not_includes assigns(:interventions), ordinaire
  end

  test 'index : aucun mot clé soumis → liste non restreinte' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Sans mot clé')

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'index : deux mots clés → seulement les interventions qui portent les deux' do
    sign_in users(:administrateur_paris)
    les_deux = cree_intervention_index('Porte les deux', tag_list: 'urgence, plomberie')
    un_seul = cree_intervention_index('N’en porte qu’un', tag_list: 'urgence')

    get interventions_url, params: { tags: %w[urgence plomberie] }

    assert_response :success
    assert_includes assigns(:interventions), les_deux
    assert_not_includes assigns(:interventions), un_seul
  end

  test 'index : mot clé dans une autre casse → les interventions correspondantes' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')

    get interventions_url, params: { tags: ['URGENCE'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente
  end

  test 'index : mot clé inconnu → liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { tags: ['mot-clé-qui-n-existe-pas'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'index : filtre de mots clés vidé → liste non restreinte' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin filtre vidé')

    get interventions_url, params: { tags: [''] }

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'index : paramètre tags scalaire → accepté au lieu de faire tomber la page' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')

    get interventions_url, params: { tags: 'urgence' }

    assert_response :success
    assert_includes assigns(:interventions), urgente
  end

  test 'index : paramètre tags non textuel → ignoré, liste non restreinte' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin tags non textuel')

    get interventions_url, params: { tags: { a: 'b' } }

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'index : liste des services proposée à un administrateur → toute son organisation' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
    assert_includes assigns(:services), services(:comptabilite)
  end

  test 'index : liste des services proposée à un manager → ses services seulement' do
    get interventions_url

    assert_response :success
    assert_not_includes assigns(:services), services(:comptabilite)
  end

  test 'index : liste des adhérents pour un administrateur → non restreinte par le filtre service' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_includes assigns(:adhérents), users(:weil)
  end

  test 'index : liste des adhérents pour un manager → restreinte au filtre service' do
    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_not_includes assigns(:adhérents), users(:weil)
  end

  test 'index : format xls → un classeur Excel est téléchargé' do
    sign_in users(:administrateur_paris)

    get interventions_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.media_type
    assert_match(/Interventions_.*\.xls/, response.headers['Content-Disposition'])
  end

  # ==================== TESTS CRITIQUES ====================

  # rôles.
  test "index : l'export XLS d'un agent ne contient ni évaluation ni avis (critique)" do
    agent = users(:électricité)
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

  # (la correction B25 ne doit pas les faire disparaître pour tout le monde).
  test "index : l'export XLS d'un manager contient les évaluations et avis (critique)" do
    get interventions_url(format: :xls) # hidalgo (manager) connecté par le setup

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    en_tetes = sheet.row(0).to_a
    assert_includes en_tetes, 'Évaluation'
    assert_includes en_tetes, 'Avis'
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, interventions(:tonte_locaux).avis
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'show : une intervention de son périmètre → la page répond' do
    get intervention_url(@intervention)
    assert_response :success
  end

  test 'show : une intervention géolocalisée → la page répond' do
    get intervention_url(interventions(:intervention_with_location))
    assert_response :success
    assert_select "#map"
  end

  # ==================== TESTS CRITIQUES ====================

  # contenir ni l'avis ni la section Évaluation.
  test 'show : un agent ne voit pas son évaluation (critique)' do
    agent = users(:électricité)
    intervention = cree_intervention_evaluee(agent)
    sign_in agent

    get intervention_url(intervention)

    assert_response :success, "garde anti-faux-positif : l'agent doit accéder à la page"
    assert_no_match AVIS_SENTINELLE, response.body
  end

  # ==================== /TESTS CRITIQUES ====================

  test "show : format pdf → l'affiche QRCode du modèle de pointage" do
    # hidalgo (manager, service technique) est connecté via le setup.
    get intervention_url(interventions(:intervention_repete), format: :pdf)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'new : sans paramètre → la page répond' do
    get new_intervention_url
    assert_response :success
  end

  test 'new : par un manager → liste des agents à plat, câblée au service' do
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

  test 'new : par un agent → le formulaire agent est rendu' do
    sign_in users(:martin_technique_paris)
    get new_intervention_url
    assert_response :success
    # L'agent qui crée est obligatoire (data-mandatory) dans la liste plate
    assert_select "select[name='intervention[agent_ids][]'] option[data-mandatory='true']"
  end

  test 'create : paramètres valides → l’intervention est créée' do
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

  test "create : par un agent à postériori → l'intervention est terminée d'emblée" do
    # nettoyage n'a aucune intervention de fixture, donc jamais de conflit d'horaire
    # avec la plage créée ici.
    agent = users(:nettoyage)
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

  # transformer en 0, qui se lirait comme un choix de l'utilisateur.
  test 'create : par un manager → aucun temps de pause inventé' do
    post interventions_url, params: {
      intervention: {
        description: 'Élagage à planifier',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        début_prévue: 2.days.from_now,
        fin_prévue: 2.days.from_now + 2.hours,
        temps_de_pause: ''
      }
    }

    intervention = Intervention.find_by(description: 'Élagage à planifier')
    assert intervention, 'garde : la création doit avoir abouti'
    assert_nil intervention.temps_de_pause
  end

  test 'create : par un adhérent → la notification managers « nouvelle demande » est enfilée' do
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

  test 'create : par un agent à postériori → la notification managers « réalisée » est enfilée' do
    # nettoyage et pas martin : cf. le test « à postériori » ci-dessus (B10).
    agent = users(:nettoyage)
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

  test 'create : par un manager → aucune notification managers' do
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

  test 'create : par un manager avec des mots clés → ils sont enregistrés' do
    post interventions_url,
         params: { intervention: { description: 'Création avec mots clés',
                                   adherent_id: users(:weil).id,
                                   service_id: services(:technique).id,
                                   tags_manager: ['', 'urgence', 'plomberie'] } }

    créée = Intervention.find_by(description: 'Création avec mots clés')
    assert_not_nil créée, "garde : la création doit avoir abouti (#{flash[:alert]})"
    assert_equal %w[urgence plomberie], créée.tag_list
  end

  test 'create : par un agent avec des mots clés → ils sont enregistrés' do
    agent = users(:nettoyage) # aucune intervention de fixture : jamais de conflit d'horaire
    sign_in agent

    travel_to Time.current.middle_of_day do
      post interventions_url,
           params: { intervention: { début: 2.hours.ago, fin: 1.hour.ago,
                                     description: 'Bon d\'intervention avec mots clés',
                                     adherent_id: users(:patrick_adherent_paris).id,
                                     service_id: services(:technique).id,
                                     agent_ids: [agent.id],
                                     tags_intervenant: ['', 'élagage'] } }
    end

    créée = Intervention.find_by(description: 'Bon d\'intervention avec mots clés')
    assert_not_nil créée, "garde : la création doit avoir abouti (#{flash[:alert]})"
    assert_equal ['élagage'], créée.tag_list
  end

  test 'create : refusée → la liste des agents suit le service soumis' do
    post interventions_url, params: {
      intervention: { service_id: services(:informatique).id,
                      adherent_id: users(:weil).id,
                      agent_ids: ['', users(:martin_technique_paris).id],
                      description: 'Nouvelle demande' }
    }

    assert_response :unprocessable_content
    ids = assigns(:agents).map(&:last)
    assert_includes ids, users(:hidalgo).id
    assert_not_includes ids, users(:martin_technique_paris).id
  end

  test 'create : un modèle de pointage → ses mots clés sont enregistrés' do
    post create_intervention_modele_pointage_interventions_url,
         params: { intervention: { description: 'Modèle avec mots clés',
                                   adherent_id: users(:weil).id,
                                   service_id: services(:technique).id,
                                   tags_manager: ['', 'tonte'] } }

    modele = Intervention.find_by(description: 'Modèle avec mots clés')
    assert_not_nil modele, "garde : la création doit avoir abouti (#{flash[:alert]})"
    assert_equal ['tonte'], modele.tag_list
  end

  test 'edit : une intervention de son périmètre → la page répond' do
    get edit_intervention_url(@intervention)
    assert_response :success
  end

  test 'edit : une intervention avec des photos → la page répond' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    get edit_intervention_url(@intervention)

    assert_response :success
    # Sans `multiple`, le param redevient scalaire et la photo est perdue.
    assert_select "input[type=file][name='intervention[photos][]'][multiple]"
  end

  test 'edit : une intervention avec des photos de demande → la page répond' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    get edit_intervention_url(@intervention)

    assert_response :success
    assert_select "input[type=file][name='intervention[photos_demande][]'][multiple]"
  end

  # ==================== TESTS CRITIQUES ====================

  test 'edit : le formulaire de terminaison rend la pause obligatoire (critique)' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause[required]'
  end

  test 'edit : le formulaire de terminaison rend les agents obligatoires (critique)' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'label[for=intervention_agent_ids] span.text-red-500'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'edit : formulaire ordinaire → les agents restent facultatifs' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_agent_ids'
    assert_select 'label[for=intervention_agent_ids] span.text-red-500', false
  end

  test 'edit : formulaire ordinaire → la pause reste facultative' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause'
    assert_select 'select#intervention_temps_de_pause[required]', false
  end

  test "edit : une fille de pointage → aucun choix d'adhérent" do
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

  test "edit : une fille de pointage → le champ Agents est désactivé pour l'agent" do
    agent = users(:martin_technique_paris)
    sign_in agent
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    get edit_intervention_url(fille)

    assert_response :success
    assert_select 'select#intervention_agent_ids[disabled]'
  end

  test 'edit : hors pointage → un agent garde le choix des agents' do
    agent = users(:martin_technique_paris)
    sign_in agent

    get edit_intervention_url(interventions(:nouvelle_intervention))

    assert_response :success
    assert_select 'select#intervention_agent_ids[disabled]', false
  end

  test 'update : paramètres valides → l’intervention est modifiée' do
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

  # ==================== TESTS CRITIQUES ====================

  test 'update : workflow_state soumis en paramètre → état inchangé (critique)' do
    intervention = interventions(:nouvelle_intervention)
    état_avant = intervention.workflow_state

    patch intervention_url(intervention),
          params: { intervention: { description: intervention.description, workflow_state: 'validé' } }

    assert_equal état_avant, intervention.reload.workflow_state
  end

  test 'update : par un agent, note et avis soumis → évaluation inchangée (critique)' do
    sign_in users(:bond)
    intervention = interventions(:nouvelle_intervention)
    note_avant = intervention.note

    patch intervention_url(intervention),
          params: { intervention: { description: intervention.description, note: 5, avis: 'Excellent travail' } }

    intervention.reload
    assert_equal note_avant, intervention.note
    assert_not_equal 'Excellent travail', intervention.avis
  end

  # formulaire, et l'enregistrement termine l'intervention.
  test 'update : demande de terminaison → l’intervention est terminée (critique)' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.terminé?
    assert_equal 'Intervention terminée', flash[:notice]
  end

  test 'update : demande de terminaison sans date de fin → refusé (critique)' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: '', description: intervention.description }
    }

    assert_response :unprocessable_content
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
    assert_match(/est obligatoire pour terminer l.*intervention/, response.body)
  end

  # terminée sans agent vaut 0 heure et ne doit pas pouvoir être enregistrée.
  test 'update : demande de terminaison sans agent → refusé (critique)' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description, agent_ids: [''] }
    }

    assert_response :unprocessable_content
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
    assert_match(/Au moins un agent est obligatoire/, response.body)
  end

  # modifier une intervention, mais jamais la terminer.
  test 'update : un adhérent ne peut pas terminer via le paramètre (critique)' do
    intervention = interventions(:intervention_paris)
    sign_in users(:patrick_adherent_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'update : sans demande de terminaison → état inchangé' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?
  end

  test 'update : paramètres invalides → formulaire réaffiché en 422' do
    patch intervention_url(@intervention), params: { intervention: { description: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @intervention.reload.description
  end

  test 'update : une photo soumise en tableau → elle est ajoutée' do
    assert_difference('@intervention.photos.count', 1) do
      patch intervention_url(@intervention), params: {
        intervention: { photos: [fixture_file_upload('exemple.png', 'image/png')] }
      }
    end
  end

  test 'update : photos ré-émises en signed_id → conservées, la nouvelle ajoutée' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    existante = @intervention.photos.first

    patch intervention_url(@intervention), params: {
      intervention: { photos: [existante.signed_id, fixture_file_upload('exemple.png', 'image/png')] }
    }

    assert_equal 2, @intervention.reload.photos.count
  end

  test 'update : une photo de demande → les photos de réalisation restent intactes' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos_demande.count', 1) do
      assert_no_difference('@intervention.photos.count') do
        patch intervention_url(@intervention), params: {
          intervention: { photos_demande: [fixture_file_upload('exemple.png', 'image/png')] }
        }
      end
    end
  end

  test 'update : photos de demande ré-émises en signed_id → conservées, la nouvelle ajoutée' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save
    existante = @intervention.photos_demande.first

    patch intervention_url(@intervention), params: {
      intervention: { photos_demande: [existante.signed_id, fixture_file_upload('exemple.png', 'image/png')] }
    }

    assert_equal 2, @intervention.reload.photos_demande.count
  end

  test "update : une photo de demande → l'ajout est tracé dans l'audit" do
    assert_difference('@intervention.audits.count', 1) do
      patch intervention_url(@intervention), params: {
        intervention: { photos_demande: [fixture_file_upload('exemple.png', 'image/png')] }
      }
    end

    assert_equal 'photo de la demande ajoutée', @intervention.audits.last.comment.sub(/\A\d+ /, '')
  end

  test "update : depuis le pointage statut → redirection vers l'accueil" do
    intervention = interventions(:intervention_fille)

    patch intervention_url(intervention),
          params: { intervention: { commentaires: 'Terminé côté agent' },
                    commit: 'Enregistrer le commentaire' }

    assert_redirected_to root_path
    assert_equal 'Terminé côté agent', intervention.reload.commentaires
  end

  test 'update : saisie a posteriori, fin antérieure au début → refusé en 422' do
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

  test 'update : saisie a posteriori, dates futures → refusé en 422' do
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

  test "update : par un agent hors pointage → l'adhérent reste modifiable" do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    sign_in agent

    patch intervention_url(intervention), params: {
      intervention: { adherent_id: users(:patrick_adherent_paris).id, description: intervention.description }
    }

    assert_equal users(:patrick_adherent_paris), intervention.reload.adherent
  end

  test "update : par un manager sur une fille de pointage → l'adhérent reste modifiable" do
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

  test 'update : un second agent sur une fille de pointage → refusé' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)
    agents_initiaux = fille.agent_ids

    sign_in users(:hidalgo)
    patch intervention_url(fille), params: {
      intervention: { agent_ids: ['', users(:martin_technique_paris).id, users(:john_wick).id],
                      description: 'Pointage à deux' }
    }

    assert_response :unprocessable_content
    fille.reload
    assert_equal agents_initiaux, fille.agent_ids, "les lignes de jointure ne doivent pas être écrites"
    assert_not_equal 'Pointage à deux', fille.description
  end

  test 'update : après ce refus → le formulaire réaffiché conserve la saisie' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    sign_in users(:hidalgo)
    patch intervention_url(fille), params: {
      intervention: { agent_ids: ['', users(:martin_technique_paris).id, users(:john_wick).id],
                      description: 'Pointage à deux', commentaires: 'Commentaire saisi' }
    }

    assert_response :unprocessable_content
    assert_select "input#intervention_description[value=?]", 'Pointage à deux'
    assert_select 'textarea#intervention_commentaires', text: /Commentaire saisi/
  end

  test 'update : après un refus → les agents et outils soumis sont conservés' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)
    outil = tools(:tondeuse)

    sign_in users(:hidalgo)
    patch intervention_url(fille), params: {
      intervention: { agent_ids: ['', users(:martin_technique_paris).id, users(:électricité).id],
                      tool_ids: ['', outil.id], description: 'Pointage à deux' }
    }

    assert_response :unprocessable_content
    assert_select "select#intervention_agent_ids option[selected][value=?]", users(:martin_technique_paris).id.to_s
    assert_select "select#intervention_agent_ids option[selected][value=?]", users(:électricité).id.to_s
    assert_select "select#intervention_tool_ids option[selected][value=?]", outil.id.to_s
    assert_empty fille.reload.tool_ids, "les outils soumis ne doivent pas être écrits en base"
  end

  test 'update : réussi → les outils sont enregistrés' do
    sign_in users(:hidalgo)
    intervention = interventions(:nouvelle_intervention)
    outil = tools(:outil_paris)

    patch intervention_url(intervention), params: {
      intervention: { description: intervention.description, tool_ids: ['', outil.id] }
    }

    assert_equal [outil.id], intervention.reload.tool_ids
  end

  test 'update : une fille de pointage → son agent reste remplaçable' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    sign_in users(:hidalgo)
    patch intervention_url(fille), params: {
      intervention: { agent_ids: ['', users(:électricité).id], description: fille.description }
    }

    assert_equal [users(:électricité).id], fille.reload.agent_ids
  end

  test 'update : hors pointage → plusieurs agents restent acceptés' do
    sign_in users(:hidalgo)
    intervention = interventions(:nouvelle_intervention)

    patch intervention_url(intervention), params: {
      intervention: { agent_ids: ['', users(:bond).id, users(:électricité).id],
                      description: intervention.description }
    }

    assert_equal [users(:bond).id, users(:électricité).id].sort, intervention.reload.agent_ids.sort
  end

  test 'update : refusé → la liste des agents suit le service soumis' do
    intervention = interventions(:nouvelle_intervention)

    patch intervention_url(intervention), params: {
      intervention: { service_id: services(:informatique).id,
                      agent_ids: ['', users(:martin_technique_paris).id],
                      description: intervention.description }
    }

    assert_response :unprocessable_content
    ids = assigns(:agents).map(&:last)
    assert_includes ids, users(:hidalgo).id
    assert_not_includes ids, users(:martin_technique_paris).id
  end

  test 'update : par un adhérent → les mots clés sont conservés' do
    @intervention.update!(tag_list: 'urgence, plomberie')
    sign_in users(:weil)

    patch intervention_url(@intervention),
          params: { intervention: { description: 'Description revue par l’adhérent' } }

    assert_redirected_to intervention_url(@intervention)
    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'update : par un manager qui vide les mots clés → ils sont retirés' do
    @intervention.update!(tag_list: 'urgence, plomberie')

    # Un select multiple vidé reste soumis, grâce au champ caché de Rails.
    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description, tags_manager: [''] } }

    assert_redirected_to intervention_url(@intervention)
    assert_empty @intervention.reload.tag_list
  end

  test 'update : par un manager → les mots clés sont modifiés' do
    @intervention.update!(tag_list: 'urgence')

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_manager: ['', 'urgence', 'plomberie'] } }

    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'update : par un agent → les mots clés sont modifiés' do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:bond)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_intervenant: ['', 'élagage'] } }

    assert_equal ['élagage'], @intervention.reload.tag_list
  end

  test "update : un manager qui soumet tags_intervenant → le champ de l'autre rôle est ignoré" do
    @intervention.update!(tag_list: 'urgence')

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_intervenant: ['', 'forgé'] } }

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  test "update : un agent qui soumet tags_manager → le champ de l'autre rôle est ignoré" do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:bond)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_manager: ['', 'forgé'] } }

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  # À inverser à la correction (retrait de :tag_list des permits).
  test 'update : un adhérent qui forge tag_list → les mots clés sont écrasés' do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:weil)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description, tag_list: 'forgé' } }

    assert_equal ['forgé'], @intervention.reload.tag_list
  end

  test 'update : formulaire refusé → les mots clés saisis sont réaffichés, mot clé inédit compris' do
    @intervention.update!(tag_list: 'urgence')

    # Sans adhérent, la création est refusée : une description vide ne suffirait pas,
    # `set_temporary_description` la remplit à la création.
    post interventions_url,
         params: { intervention: { description: 'Création refusée',
                                   service_id: services(:technique).id,
                                   tags_manager: ['', 'urgence', 'mot-clé-inédit'] } }

    assert_response :unprocessable_content
    assert_select 'select#intervention_tags_manager option[selected]', text: 'urgence'
    assert_select 'select#intervention_tags_manager option[selected]', text: 'mot-clé-inédit'
  end

  test 'destroy : sans mouvement → l’intervention est supprimée' do
    assert_difference('Intervention.count', -1) do
      delete intervention_url(interventions(:nouvelle_intervention))
    end

    assert_redirected_to interventions_url
  end

  test 'destroy : avec des mouvements → aucune suppression' do
    assert_no_difference('Intervention.count') do
      delete intervention_url(@intervention)
    end

    assert_response :see_other # Redirection après erreur
  end

  # filet ne doit pas bloquer le parcours nominal.
  test 'terminer : une intervention saine → elle est terminée' do
    agent = users(:électricité)
    intervention = cree_intervention_en_conflit(agent, avec_conflit: false)
    sign_in agent

    post terminer_intervention_url(intervention)

    assert intervention.reload.terminé?
  end

  # ==================== TESTS CRITIQUES ====================

  # le chemin de terminaison, sans qu'aucun formulaire ne le fournisse.
  test 'terminer : le temps total et une pause à 0 sont enregistrés (critique)' do
    agent = users(:électricité)
    intervention = cree_intervention_en_conflit(agent, avec_conflit: false)
    intervention.update_columns(temps_de_pause: nil, temps_total: nil)
    sign_in agent

    post terminer_intervention_url(intervention)

    intervention.reload
    assert intervention.terminé?
    assert_equal 0, intervention.temps_de_pause
    assert_in_delta 2.0, intervention.temps_total, 1e-6
  end

  test 'terminer : sans agent → refusé (critique)' do
    intervention = interventions(:intervention_paris)
    intervention.agents.destroy_all

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Au moins un agent est obligatoire/, flash[:alert])
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # Test critique — parcours quotidien de l'agent : terminer son intervention.
  test 'terminer : intervention en conflit → redirection au lieu d’une erreur (critique)' do
    agent = users(:électricité)
    intervention = cree_intervention_en_conflit(agent)
    sign_in agent

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert_match(/Conflit/, flash[:alert], "le motif du refus doit être affiché à l'utilisateur")
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'terminer : une intervention déjà validée → refusé' do
    intervention = cree_intervention_validee

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Impossible de terminer/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  # ==================== TESTS CRITIQUES ====================

  # Test critique — parcours quotidien : l'adhérent valide le travail terminé.
  test 'valider : l’adhérent valide une intervention terminée (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, "l'intervention doit passer à l'état validé"
  end

  # re-valider une intervention déjà validée.
  test 'valider : une intervention déjà validée → redirection avec un message (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)
    post valider_intervention_url(intervention)

    post valider_intervention_url(intervention) # 2e clic : plus en état terminé

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, 'le double-clic ne doit rien casser'
  end

  # Même filet côté adhérent, sur les deux transitions qu'il déclenche.
  test 'valider : intervention en conflit → redirection au lieu d’une erreur (critique)' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'terminé')
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  # Test critique — parcours quotidien : l'adhérent refuse le travail terminé.
  test 'refuser : l’adhérent refuse une intervention terminée (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.refusé?, "l'intervention doit passer à l'état refusé"
  end

  test 'refuser : intervention en conflit → redirection au lieu d’une erreur (critique)' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'terminé')
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'archiver : une intervention validée → elle est archivée' do
    intervention = cree_intervention_validee

    post archiver_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_equal 'archivé', intervention.reload.workflow_state
  end

  test 'archiver : une intervention déjà archivée → signalé' do
    intervention = cree_intervention_validee
    intervention.update_columns(workflow_state: 'archivé')

    post archiver_intervention_url(intervention)

    assert_match(/déjà archivée/i, flash[:alert].to_s)
  end

  test 'archiver : depuis un état impossible → refusé' do
    intervention = interventions(:nouvelle_intervention)

    post archiver_intervention_url(intervention)

    assert_match(/ne peut pas se archiver/i, flash[:alert].to_s)
    assert_equal 'nouveau', intervention.reload.workflow_state
  end

  test 'archiver : une intervention invalide → refusé avec son motif' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'validé')

    post archiver_intervention_url(intervention)

    assert_match(/n'est pas valide/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  test 'purge : une photo → elle est supprimée' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to @intervention
  end

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

    assert_equal 'Photo supprimée', @intervention.audits.last.comment
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

  test 'purge : une photo de demande est supprimée par la même action que les photos' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos_demande.count', -1) do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end

    assert_redirected_to @intervention
  end

  test 'purge : la photo de demande est réellement supprimée (blob détruit et fichier effacé)' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save
    blob = @intervention.photos_demande.first.blob

    assert_difference('ActiveStorage::Blob.count', -1) do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end

    assert_not ActiveStorage::Blob.exists?(blob.id)
    assert_not ActiveStorage::Blob.service.exist?(blob.key)
  end

  test 'purge : supprimer une photo de demande laisse les photos de réalisation intactes' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_no_difference('@intervention.photos.count') do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end

    assert_equal 0, @intervention.reload.photos_demande.count
  end

  test "purge : un agent affecté à l'intervention peut supprimer une photo de réalisation" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:bond)

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end
  end

  test 'purge : les deux actions sont cloisonnées par type de photo' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end
  end

  test "purge : l'adhérent de l'intervention peut supprimer une photo de demande" do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:weil)

    assert_difference('@intervention.photos_demande.count', -1) do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end
  end

  test "purge : impossible de supprimer la photo de demande d'une AUTRE intervention" do
    autre = interventions(:nouvelle_intervention)
    autre.photos_demande.attach(file_fixture('exemple.png'))
    autre.save
    cible = autre.photos_demande.first

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purger_photos_demande_intervention_url(@intervention), params: { photo_id: cible.id }
    end

    assert_response :not_found
  end

  test 'pointer : un modèle → une fille est créée' do
    # Le sign_in gère tout seul la déconnexion du premier sign_in dans le setup
    sign_in users(:martin_technique_paris)

    intervention = interventions(:intervention_repete)

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end
  end

  test "pointer : l'agent absent aujourd'hui → refusé avec le motif" do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0)

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(interventions(:intervention_repete))
    end

    assert_redirected_to intervention_path(interventions(:intervention_repete))
    assert_match 'Agent(s) indisponible(s)', flash[:alert]
  end

  test "pointer : l'après-midi alors que l'agent est absent le matin → accepté" do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0, matin: true)

    travel_to Time.current.change(hour: 14) do
      assert_difference('Intervention.count', 1) do
        get pointer_intervention_url(interventions(:intervention_repete))
      end
    end
  end

  test 'pointer : un modèle déjà pointé → la fille est terminée' do
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

  test "pointer : une intervention qui n'est pas un modèle → aucune fille créée" do
    intervention = interventions(:intervention_repete)
    intervention.repeter = false
    intervention.save

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(intervention)
    end
  end

  test 'pointer : un modèle à plusieurs agents → une fille par agent' do
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

  test "pointer : un enregistrement en échec → l'erreur est remontée, pas un 404" do
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

  # pas ; l'état est ici reconstitué à la main.
  test "pointer : une fille close restée nouveau → une reprise d'activité est enregistrée" do
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

  test "pointer : une intervention qui n'est pas un modèle → refusé" do
    intervention = interventions(:nouvelle_intervention) # bond y est agent affecté
    sign_in users(:bond)

    get pointer_intervention_url(intervention)

    assert_match(/n'est pas un modèle de pointage/i, flash[:alert].to_s)
  end

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

  test 'pointer : plusieurs scans dans la journée → plusieurs filles' do
      intervention = interventions(:intervention_repete)

      sign_in users(:martin_technique_paris)
      jour = Time.zone.local(2025, 1, 6)
      assert_difference('Intervention.count', 1) do
        travel_to(jour + 8.hours) { get pointer_intervention_url(intervention) }
      end
      assert_no_difference('Intervention.count') do
        travel_to(jour + 12.hours) { get pointer_intervention_url(intervention) }
      end
      assert_difference('Intervention.count', 1) do
        travel_to(jour + 13.hours) { get pointer_intervention_url(intervention) }
      end
      assert_no_difference('Intervention.count') do
        travel_to(jour + 17.hours) { get pointer_intervention_url(intervention) }
      end
      expected_nb_intervention_filles = 2
      actual_nb_intervention_filles = Intervention.where(template_slug: intervention.slug).last(2).count

      assert_equal expected_nb_intervention_filles, actual_nb_intervention_filles
  end

  test 'pointage_statut : un modèle répété → redirection vers la fille du pointeur' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)

    # On crée d'abord une fille (clock in) pour que la redirection ait une cible.
    get pointer_intervention_url(modele)

    get pointage_statut_intervention_url(modele)
    assert_response :redirect
  end

  test 'update_location : une fille de pointage → la géolocalisation est ajoutée' do
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

  test 'update_location : une intervention invalide → erreurs en 422' do
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

  test 'get_unavailable_elements : agent occupé sur les dates réelles → son id est renvoyé' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : dates réelles disjointes → aucun agent renvoyé' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : réel disjoint mais prévu chevauchant → aucun agent renvoyé' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00',
                                début_prévue: '2025-04-08 14:00', fin_prévue: '2025-04-08 17:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : réel absent → repli sur les dates prévues' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début_prévue: '2025-04-08 09:00', fin_prévue: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut_prevue: '2025-04-08 10:00',
                                     date_fin_prevue: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : bornes mixtes réelle et prévue → conflit détecté' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 10:30', date_fin_prevue: '2025-04-08 11:30')

    assert_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : le réel prime sur le prévu borne par borne → aucun conflit' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 13:00',
                                     date_debut_prevue: '2025-04-08 10:30',
                                     date_fin: '2025-04-08 14:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : outil occupé sur la plage → son id est renvoyé' do
    sign_in users(:administrateur_paris)
    tool = tools(:tondeuse)
    adherent = users(:weil)
    Intervention.create!(description: 'Occupe l’outil', organisation: organisations(:mairie_paris),
                         tools: [tool], adherent: adherent, service: adherent.services.first,
                         début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00',
                                     agents_ids: '', tool_ids: tool.id.to_s)

    assert_includes json['tools'], tool.id
  end

  test 'get_unavailable_elements : agent absent sur la plage → son id est renvoyé' do
    sign_in users(:administrateur_paris)
    Absence.create!(du: '2025-04-08', au: '2025-04-08', motif: 0, user: users(:bond))

    json = interroger_disponibilites(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'get_unavailable_elements : aucune date fournie → réponse vide sans erreur' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites

    assert_empty json['agents']
    assert_empty json['tools']
  end

  test 'services_for_adherent : un adhérent du périmètre → ses services en JSON' do
    get services_for_adherent_interventions_url(adherent_id: users(:weil).id)

    assert_response :success
    noms = response.parsed_body.map { |service| service['nom'] }
    assert_includes noms, services(:informatique).nom
  end

  test 'services_for_adherent : les services hors du périmètre du current_user sont exclus' do
    get services_for_adherent_interventions_url(adherent_id: users(:adherent_marseille).id)

    assert_response :success
    assert_empty response.parsed_body
  end

  test 'services_for_adherent : un adherent_id inconnu répond 404 sans planter' do
    get services_for_adherent_interventions_url(adherent_id: 0)

    assert_response :not_found
  end

  test 'agents_for_service : un service → ses agents en JSON' do
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

  test 'agents_for_service : le résultat est borné au périmètre du current_user' do
    # service_marseille est hors du périmètre de hidalgo : on ne fuite pas ses agents
    get agents_for_service_interventions_url(service_id: services(:service_marseille).id), as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_not_includes ids, users(:agent_marseille).id
    # Service hors périmètre ⇒ repli sur tous les agents du current_user
    assert_includes ids, users(:martin_technique_paris).id
  end

  test 'agents_for_service : sans service → tous les agents du périmètre' do
    get agents_for_service_interventions_url, as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_includes ids, users(:martin_technique_paris).id
    assert_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'new_intervention_modele_pointage : sans paramètre → une intervention répétée est préparée' do
    get new_intervention_modele_pointage_interventions_url

    assert_response :success
    assert assigns(:intervention).repeter
  end

  test "create_intervention_modele_pointage : paramètres valides → un modèle à l'état pointage activé" do
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

  test 'create_intervention_modele_pointage : paramètres invalides → formulaire réaffiché en 422' do
    assert_no_difference('Intervention.count') do
      post create_intervention_modele_pointage_interventions_url,
           params: { intervention: { description: '' } }
    end

    assert_response :unprocessable_content
  end

  # L'agent affecté ouvre SA propre intervention validée : la page ne doit

  private

  def cree_intervention_evaluee(agent)
    Intervention.create!(
      description: 'Intervention évaluée du test critique',
      adherent: users(:weil),
      service: services(:technique),
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

  def cree_intervention_validee
    Intervention.create!(
      description: 'Intervention validée du test',
      adherent: users(:weil),
      service: services(:technique),
      agent_ids: [users(:électricité).id],
      début: DateTime.new(2024, 5, 6, 9, 0),
      fin: DateTime.new(2024, 5, 6, 11, 0),
      temps_de_pause: 0,
      workflow_state: 'validé',
      slug: SecureRandom.uuid
    )
  end

  def cree_intervention_en_conflit(agent, workflow_state: 'nouveau', avec_conflit: true)
    intervention = Intervention.create!(
      description: 'Intervention à terminer', adherent: users(:weil), service: services(:technique),
      agent_ids: [agent.id], début: DateTime.new(2024, 3, 12, 9, 0), fin: DateTime.new(2024, 3, 12, 11, 0),
      temps_de_pause: 0, workflow_state: workflow_state, slug: SecureRandom.uuid
    )
    return intervention unless avec_conflit

    conflit = Intervention.new(
      description: 'Intervention qui recouvre la plage', adherent: users(:weil), service: services(:technique),
      début: DateTime.new(2024, 3, 12, 8, 0), fin: DateTime.new(2024, 3, 12, 12, 0),
      temps_de_pause: 0, workflow_state: 'nouveau', slug: SecureRandom.uuid
    )
    conflit.save!(validate: false)
    AgentIntervention.create!(agent: agent, intervention: conflit)

    assert_not intervention.reload.valid?, 'garde : le montage doit bien rendre l’intervention invalide'
    intervention
  end

  def cree_intervention_index(description, attributs = {})
    Intervention.create!({
      description: description,
      adherent: users(:weil),
      service: services(:technique),
      workflow_state: 'nouveau',
      slug: SecureRandom.uuid
    }.merge(attributs))
  end

  def cree_intervention_hors_services
    intervention = cree_intervention_index('Hors des services du current_user')
    intervention.update_columns(service_id: services(:comptabilite).id)
    intervention
  end

  def cree_intervention_occupante(**attrs)
    adherent = users(:weil)
    Intervention.create!({
      description: 'Intervention existante',
      organisation: organisations(:mairie_paris),
      agents: [users(:bond)],
      adherent: adherent,
      service: adherent.services.first
    }.merge(attrs))
  end

  def en_utc(valeur)
    return valeur if valeur == 'null'

    Time.zone.parse(valeur).utc.iso8601
  end

  def interroger_disponibilites(date_debut: 'null', date_fin: 'null', date_debut_prevue: 'null',
                                date_fin_prevue: 'null', agents_ids: nil, tool_ids: '')
    get get_unavailable_elements_interventions_url, params: {
      intervention_id: 'null',
      agents_ids: agents_ids || users(:bond).id.to_s,
      tool_ids: tool_ids,
      date_debut_prevue: en_utc(date_debut_prevue),
      date_fin_prevue: en_utc(date_fin_prevue),
      date_debut: en_utc(date_debut),
      date_fin: en_utc(date_fin)
    }

    assert_response :success
    JSON.parse(response.body)
  end
end
