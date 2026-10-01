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

  test 'un slug d’intervention inconnu redirige sans planter' do
    get intervention_url('abcdefg')
    assert_redirected_to root_path
  end

  # ==================== TESTS CRITIQUES ====================

  test "le filtre par un mot clé d'une autre organisation ne retourne aucune intervention (critique)" do
    sign_in users(:administrateur_paris)
    interventions(:nettoyage_port).update!(tag_list: 'secret-marseille')

    get interventions_url, params: { tags: ['secret-marseille'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test "la liste des mots clés proposée au filtre est bornée à l'organisation (critique)" do
    sign_in users(:administrateur_paris)
    interventions(:nettoyage_port).update!(tag_list: 'secret-marseille')
    @intervention.update!(tag_list: 'urgence')

    get interventions_url

    assert_response :success
    noms = assigns(:intervention_tags).map(&:name)
    assert_includes noms, 'urgence'
    assert_not_includes noms, 'secret-marseille'
  end

  test "l'export XLS ne contient aucune intervention d'une autre organisation (critique)" do
    get interventions_url(format: :xls)

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, interventions(:tonte_locaux).description
    assert_not_includes contenu, interventions(:nettoyage_port).description
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la liste des interventions est affichée avec succès' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
  end

  test 'un administrateur sans filtre service voit les interventions de toute son organisation' do
    sign_in users(:administrateur_paris)
    hors_perimetre = cree_intervention_hors_services

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), hors_perimetre
    assert_empty assigns(:selected_service_ids)
  end

  test 'un administrateur qui filtre sur un service ne voit que les interventions de ce service' do
    sign_in users(:administrateur_paris)
    comptabilite = cree_intervention_hors_services

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_includes assigns(:interventions), comptabilite
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'un manager sans filtre service voit les interventions de tous ses services' do
    technique = cree_intervention_index('Dans ses services', service: services(:technique))

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), technique
    assert_empty assigns(:selected_service_ids)
  end

  test 'un filtre service forgé hors périmètre par un manager se replie sur ses services' do
    hors_perimetre = cree_intervention_hors_services

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_not_includes assigns(:interventions), hors_perimetre
  end

  test 'un adhérent sans filtre service voit toutes ses interventions' do
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

  test 'un adhérent qui filtre sur un service ne voit que les interventions de ce service' do
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

  test 'la liste sans filtre exclut les interventions archivées' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url

    assert_response :success
    assert_not_includes assigns(:interventions), archivee
  end

  test 'la liste des archives ne retourne que les interventions archivées' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url(archives: '1')

    assert_response :success
    assert_includes assigns(:interventions), archivee
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'la liste filtrée par un statut ne retourne que les interventions de cet état' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { workflow_state: ['Nouveau'] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'la liste filtrée par plusieurs statuts retourne les interventions de chacun de ces états' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { workflow_state: %w[Nouveau Terminé] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_includes assigns(:interventions), interventions(:intervention_terminée)
    assert_not_includes assigns(:interventions), @intervention
  end

  test 'un filtre de statut vidé retombe sur les interventions non archivées' do
    sign_in users(:administrateur_paris)
    archivee = cree_intervention_index('Intervention archivée', workflow_state: 'archivé')

    get interventions_url, params: { workflow_state: [''] }

    assert_response :success
    assert_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_not_includes assigns(:interventions), archivee
  end

  test 'la recherche sur la description ne retourne que les interventions correspondantes' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'Tonte locaux')

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'la recherche trouve une intervention par ses commentaires' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'bord des routes')

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'une recherche sans correspondance renvoie une liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url(search: 'zzz-aucune-correspondance-zzz')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'la liste filtrée par un intervalle de dates ne retourne que les interventions qui commencent dans l’intervalle' do
    sign_in users(:administrateur_paris)
    jour = @intervention.début.to_date

    get interventions_url(du: jour.to_s, au: jour.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'la liste filtrée par la seule date de début retourne les interventions qui commencent ou finissent ce jour' do
    sign_in users(:administrateur_paris)

    get interventions_url(du: @intervention.début.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'la liste filtrée par la seule date de fin retourne les interventions qui finissent ce jour' do
    sign_in users(:administrateur_paris)

    get interventions_url(au: @intervention.fin.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
  end

  test 'un intervalle de dates sans intervention renvoie une liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url(du: '1900-01-01', au: '1900-01-02')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'la liste filtrée par adhérent ne retourne que les interventions de cet adhérent' do
    sign_in users(:administrateur_paris)

    get interventions_url(adherent_id: users(:weil).id)

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_adhérent)
  end

  test 'la liste filtrée par agent ne retourne que les interventions de cet agent' do
    sign_in users(:administrateur_paris)

    get interventions_url(agent_ids: [users(:bond).id])

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_agent)
  end

  test 'la liste filtrée par outil ne retourne que les interventions utilisant cet outil' do
    sign_in users(:administrateur_paris)

    get interventions_url(tool_ids: [tools(:tondeuse).id])

    assert_response :success
    assert_includes assigns(:interventions), @intervention
    assert_not_includes assigns(:interventions), interventions(:intervention_terminée)
  end

  test 'un paramètre équipe forgé est ignoré et ne restreint pas la liste' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin équipe')

    [['mairie'], 'mairie'].each do |valeur|
      get interventions_url(equipe: valeur)

      assert_response :success
      assert_includes assigns(:interventions), temoin
    end
  end

  test 'la liste filtrée par un mot clé ne retourne que les interventions qui le portent' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')
    ordinaire = cree_intervention_index('Ordinaire')

    get interventions_url, params: { tags: ['urgence'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente
    assert_not_includes assigns(:interventions), ordinaire
  end

  test 'la liste sans mot clé soumis n’est pas restreinte' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Sans mot clé')

    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'la liste filtrée par deux mots clés ne retourne que les interventions qui portent les deux' do
    sign_in users(:administrateur_paris)
    les_deux = cree_intervention_index('Porte les deux', tag_list: 'urgence, plomberie')
    un_seul = cree_intervention_index('N’en porte qu’un', tag_list: 'urgence')

    get interventions_url, params: { tags: %w[urgence plomberie] }

    assert_response :success
    assert_includes assigns(:interventions), les_deux
    assert_not_includes assigns(:interventions), un_seul
  end

  test 'le filtre par mot clé est insensible à la casse' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')

    get interventions_url, params: { tags: ['URGENCE'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente
  end

  test 'un mot clé inconnu renvoie une liste vide' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { tags: ['mot-clé-qui-n-existe-pas'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'un filtre de mots clés vidé ne restreint pas la liste' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin filtre vidé')

    get interventions_url, params: { tags: [''] }

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'un paramètre tags scalaire filtre comme un mot clé au lieu de faire tomber la page' do
    sign_in users(:administrateur_paris)
    urgente = cree_intervention_index('Urgente', tag_list: 'urgence')

    get interventions_url, params: { tags: 'urgence' }

    assert_response :success
    assert_includes assigns(:interventions), urgente
  end

  test 'un paramètre tags non textuel est ignoré et ne restreint pas la liste' do
    sign_in users(:administrateur_paris)
    temoin = cree_intervention_index('Témoin tags non textuel')

    get interventions_url, params: { tags: { a: 'b' } }

    assert_response :success
    assert_includes assigns(:interventions), temoin
  end

  test 'la liste des services proposée au filtre à un administrateur couvre toute son organisation' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
    assert_includes assigns(:services), services(:comptabilite)
  end

  test 'la liste des services proposée au filtre à un manager ne contient que ses services' do
    get interventions_url

    assert_response :success
    assert_not_includes assigns(:services), services(:comptabilite)
  end

  test 'la liste des adhérents proposée à un administrateur n’est pas restreinte par le filtre service' do
    sign_in users(:administrateur_paris)

    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_includes assigns(:adhérents), users(:weil)
  end

  test 'la liste des adhérents proposée à un manager est restreinte au filtre service' do
    get interventions_url, params: { service: [services(:service_paris).id] }

    assert_response :success
    assert_not_includes assigns(:adhérents), users(:weil)
  end

  test 'la liste des interventions est téléchargée au format XLS' do
    sign_in users(:administrateur_paris)

    get interventions_url(format: :xls)

    assert_response :success
    assert_equal 'application/xls', response.media_type
    assert_match(/Interventions_.*\.xls/, response.headers['Content-Disposition'])
  end

  # ==================== TESTS CRITIQUES ====================

  # rôles.
  test "l'export XLS d'un agent ne contient ni évaluation ni avis (critique)" do
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
  test "l'export XLS d'un manager contient les évaluations et les avis (critique)" do
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

  test 'une intervention est affichée avec succès' do
    get intervention_url(@intervention)
    assert_response :success
  end

  test 'une intervention géolocalisée est affichée avec sa carte' do
    get intervention_url(interventions(:intervention_with_location))
    assert_response :success
    assert_select "#map"
  end

  # ==================== TESTS CRITIQUES ====================

  # contenir ni l'avis ni la section Évaluation.
  test 'un agent ne voit pas son évaluation sur la page de l’intervention (critique)' do
    agent = users(:électricité)
    intervention = cree_intervention_evaluee(agent)
    sign_in agent

    get intervention_url(intervention)

    assert_response :success, "garde anti-faux-positif : l'agent doit accéder à la page"
    assert_no_match AVIS_SENTINELLE, response.body
  end

  # ==================== /TESTS CRITIQUES ====================

  test "l'affiche QRCode d'un modèle de pointage est téléchargée au format PDF" do
    # hidalgo (manager, service technique) est connecté via le setup.
    get intervention_url(interventions(:intervention_repete), format: :pdf)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'la fiche détaillée est téléchargée au format PDF' do
    get fiche_intervention_url(@intervention, filename: @intervention.pdf_filename)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
    assert_match(/Intervention-#{@intervention.id}\.pdf/, response.headers['Content-Disposition'])
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_intervention_url
    assert_response :success
  end

  test 'le formulaire de création d’un manager propose une liste d’agents à plat, rechargée selon le service' do
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

  test 'le formulaire de création d’un agent rend cet agent obligatoire dans la liste des agents' do
    sign_in users(:martin_technique_paris)
    get new_intervention_url
    assert_response :success
    # L'agent qui crée est obligatoire (data-mandatory) dans la liste plate
    assert_select "select[name='intervention[agent_ids][]'] option[data-mandatory='true']"
  end

  test 'une intervention est créée lorsque les paramètres sont valides' do
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

    assert_equal 'Intervention créée avec succès.', flash[:notice]
    assert_redirected_to intervention_url(Intervention.last)
  end

  test "une intervention saisie a posteriori par un agent naît à l'état terminé" do
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
  test 'une intervention créée par un manager sans temps de pause n’en reçoit aucun' do
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

  test 'une intervention créée sans aucune date naît avec ses quatre dates vides' do
    post interventions_url, params: {
      intervention: {
        description: 'Demande sans aucune date',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        début_prévue: '', début_prévue_hour: '', début_prévue_minute: '',
        fin_prévue: '', fin_prévue_hour: '', fin_prévue_minute: '',
        début: '', début_hour: '', début_minute: '',
        fin: '', fin_hour: '', fin_minute: ''
      }
    }

    intervention = Intervention.find_by(description: 'Demande sans aucune date')
    assert intervention, 'garde : la création doit avoir abouti'
    assert_nil intervention.début_prévue
    assert_nil intervention.fin_prévue
    assert_nil intervention.début
    assert_nil intervention.fin
  end

  test 'les dates prévues sont enregistrées avec l’heure et la minute choisies dans le formulaire' do
    post interventions_url, params: {
      intervention: {
        description: 'Élagage planifié à l’heure',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        début_prévue: '2030-05-04', début_prévue_hour: '8', début_prévue_minute: '15',
        fin_prévue: '2030-05-04', fin_prévue_hour: '17', fin_prévue_minute: '45'
      }
    }

    intervention = Intervention.find_by(description: 'Élagage planifié à l’heure')
    assert intervention, 'garde : la création doit avoir abouti'
    assert_equal Time.zone.local(2030, 5, 4, 8, 15), intervention.début_prévue
    assert_equal Time.zone.local(2030, 5, 4, 17, 45), intervention.fin_prévue
  end

  test 'les dates réelles sont enregistrées avec l’heure et la minute choisies dans le formulaire' do
    post interventions_url, params: {
      intervention: {
        description: 'Élagage réalisé à l’heure',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        début: '2024-04-19', début_hour: '9', début_minute: '5',
        fin: '2024-04-19', fin_hour: '18', fin_minute: '45'
      }
    }

    intervention = Intervention.find_by(description: 'Élagage réalisé à l’heure')
    assert intervention, 'garde : la création doit avoir abouti'
    assert_equal Time.zone.local(2024, 4, 19, 9, 5), intervention.début
    assert_equal Time.zone.local(2024, 4, 19, 18, 45), intervention.fin
  end

  test 'une intervention créée avec une date de début sans heure ni minute démarre à minuit' do
    date_saisie = interventions(:nouvelle_intervention).début.to_date
    expected = date_saisie.beginning_of_day

    post interventions_url, params: {
      intervention: {
        description: 'Élagage sans heure saisie',
        adherent_id: users(:patrick_adherent_paris).id,
        service_id: services(:technique).id,
        début: date_saisie.to_s, début_hour: '', début_minute: ''
      }
    }

    intervention = Intervention.find_by(description: 'Élagage sans heure saisie')
    assert intervention, 'garde : la création doit avoir abouti'
    actual = intervention.début
    assert_equal expected, actual
  end

  test 'une intervention créée par un adhérent naît à l’état nouveau' do
    adherent = users(:weil)
    sign_in adherent

    post interventions_url, params: { intervention: {
      description: 'Remplacer une ampoule du hall',
      adherent_id: adherent.id,
      service_id: services(:technique).id,
      début_prévue: 2.days.from_now,
      fin_prévue: 2.days.from_now + 2.hours
    } }

    créée = Intervention.order(:id).last
    assert_redirected_to intervention_url(créée)
    assert_equal Intervention::NOUVEAU, créée.workflow_state
  end

  test 'une intervention créée par un adhérent enfile la notification « nouvelle demande » destinée aux managers' do
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

  test 'une intervention saisie a posteriori par un agent enfile la notification « réalisée » destinée aux managers' do
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

  test 'une intervention créée par un manager n’enfile aucune notification destinée aux managers' do
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

  test 'les mots clés saisis par un manager à la création sont enregistrés' do
    post interventions_url,
         params: { intervention: { description: 'Création avec mots clés',
                                   adherent_id: users(:weil).id,
                                   service_id: services(:technique).id,
                                   tags_manager: ['', 'urgence', 'plomberie'] } }

    créée = Intervention.find_by(description: 'Création avec mots clés')
    assert_not_nil créée, "garde : la création doit avoir abouti (#{flash[:alert]})"
    assert_equal %w[urgence plomberie], créée.tag_list
  end

  test 'les mots clés saisis par un agent à la création sont enregistrés' do
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

  test 'une intervention sans service n’est pas enregistrée (critique)' do
    assert_no_difference('Intervention.count') do
      post interventions_url, params: { intervention: {
        description: 'Demande sans service',
        adherent_id: users(:weil).id,
        service_id: ''
      } }
    end

    assert_response :unprocessable_content
  end

  test 'une intervention dont la fin prévue précède le début n’est pas enregistrée' do
    assert_no_difference('Intervention.count') do
      post interventions_url, params: { intervention: {
        description: 'Créneau incohérent',
        adherent_id: users(:weil).id,
        service_id: services(:informatique).id,
        début_prévue: 3.days.from_now,
        fin_prévue: 2.days.from_now
      } }
    end

    assert_response :unprocessable_content
  end

  test 'le formulaire de création réaffiché après un refus propose les agents du service soumis' do
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

  test 'les mots clés saisis à la création d’un modèle de pointage sont enregistrés' do
    post create_intervention_modele_pointage_interventions_url,
         params: { intervention: { description: 'Modèle avec mots clés',
                                   adherent_id: users(:weil).id,
                                   service_id: services(:technique).id,
                                   tags_manager: ['', 'tonte'] } }

    modele = Intervention.find_by(description: 'Modèle avec mots clés')
    assert_not_nil modele, "garde : la création doit avoir abouti (#{flash[:alert]})"
    assert_equal ['tonte'], modele.tag_list
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_intervention_url(@intervention)
    assert_response :success
  end

  test 'le formulaire de modification d’une intervention avec des photos garde un champ photos multiple' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    get edit_intervention_url(@intervention)

    assert_response :success
    # Sans `multiple`, le param redevient scalaire et la photo est perdue.
    assert_select "input[type=file][name='intervention[photos][]'][multiple]"
  end

  test 'le formulaire de modification d’une intervention avec des photos de demande garde un champ photos de demande multiple' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    get edit_intervention_url(@intervention)

    assert_response :success
    assert_select "input[type=file][name='intervention[photos_demande][]'][multiple]"
  end

  # ==================== TESTS CRITIQUES ====================

  test 'le formulaire de terminaison rend la pause obligatoire (critique)' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause[required]'
  end

  test 'le formulaire de terminaison rend les agents obligatoires (critique)' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention, terminer: 1)

    assert_response :success
    assert_select 'label[for=intervention_agent_ids] span.text-red-500'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le formulaire de modification ordinaire laisse les agents facultatifs' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_agent_ids'
    assert_select 'label[for=intervention_agent_ids] span.text-red-500', false
  end

  test 'le formulaire de modification ordinaire laisse la pause facultative' do
    intervention = interventions(:intervention_paris)

    get edit_intervention_url(intervention)

    assert_response :success
    assert_select 'select#intervention_temps_de_pause'
    assert_select 'select#intervention_temps_de_pause[required]', false
  end

  test "le formulaire de modification d'une fille de pointage ne propose aucun choix d'adhérent" do
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

  test "le formulaire de modification d'une fille de pointage désactive le champ agents pour l'agent" do
    agent = users(:martin_technique_paris)
    sign_in agent
    modele = interventions(:intervention_repete)
    get pointer_intervention_url(modele)
    fille = Intervention.find_by(template_slug: modele.slug)

    get edit_intervention_url(fille)

    assert_response :success
    assert_select 'select#intervention_agent_ids[disabled]'
  end

  test 'le formulaire de modification d’une intervention hors pointage laisse à un agent le choix des agents' do
    agent = users(:martin_technique_paris)
    sign_in agent

    get edit_intervention_url(interventions(:nouvelle_intervention))

    assert_response :success
    assert_select 'select#intervention_agent_ids[disabled]', false
  end

  test 'une intervention est modifiée lorsque les paramètres sont valides' do
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

  test 'une modification qui ne soumet aucune date laisse les quatre dates intactes' do
    intervention = interventions(:tonte_locaux)
    dates_avant = intervention.slice(:début, :fin, :début_prévue, :fin_prévue)

    patch intervention_url(intervention), params: { intervention: { commentaires: 'Commentaire seul' } }

    intervention.reload
    assert_equal 'Commentaire seul', intervention.commentaires
    assert_equal dates_avant['début'], intervention.début
    assert_equal dates_avant['fin'], intervention.fin
    assert_equal dates_avant['début_prévue'], intervention.début_prévue
    assert_equal dates_avant['fin_prévue'], intervention.fin_prévue
  end

  test 'modifier l’heure de début d’un pointage enregistre la nouvelle heure' do
    sign_in users(:martin_technique_paris)
    scan_time = Time.current.change(sec: 27) - 2.hours
    intervention_modele = interventions(:intervention_repete)

    travel_to scan_time do
      get pointer_intervention_url(intervention_modele)
    end

    intervention_fille = Intervention.reorder(created_at: :desc).where(template_slug: intervention_modele.slug).first
    début_avant = intervention_fille.début
    début_saisi = début_avant - 1.hour
    expected = début_saisi.change(sec: 0)

    patch intervention_url(intervention_fille), params: {
      intervention: { début: début_saisi.to_date.to_s,
                      début_hour: début_saisi.hour,
                      début_minute: début_saisi.min }
    }

    actual = intervention_fille.reload.début
    assert_equal expected, actual
  end

  test 'modifier uniquement la date de début d’un pointage conserve l’heure et la minute' do
    sign_in users(:martin_technique_paris)
    scan_time = Time.current.change(sec: 27) - 2.hours
    intervention_modele = interventions(:intervention_repete)

    travel_to scan_time do
      get pointer_intervention_url(intervention_modele)
    end

    intervention_fille = Intervention.reorder(created_at: :desc).where(template_slug: intervention_modele.slug).first
    début_avant = intervention_fille.début
    date_saisie = début_avant.to_date - 1
    expected = début_avant.change(year: date_saisie.year, month: date_saisie.month,
                                  day: date_saisie.day, sec: 0)

    patch intervention_url(intervention_fille), params: {
      intervention: { début: date_saisie.to_s,
                      début_hour: début_avant.hour,
                      début_minute: début_avant.min }
    }

    actual = intervention_fille.reload.début
    assert_equal expected, actual
  end

  test 'modifier uniquement le commentaire d’un pointage laisse sa date de début inchangée' do
    sign_in users(:martin_technique_paris)
    scan_time = Time.current.change(sec: 27) - 2.hours
    intervention_modele = interventions(:intervention_repete)

    travel_to scan_time do
      get pointer_intervention_url(intervention_modele)
    end

    intervention_fille = Intervention.reorder(created_at: :desc).where(template_slug: intervention_modele.slug).first
    expected = intervention_fille.début

    patch intervention_url(intervention_fille), params: {
      intervention: { commentaires: 'Remarque saisie après le scan',
                      début: expected.to_date.to_s,
                      début_hour: expected.hour,
                      début_minute: expected.min }
    }

    intervention_fille.reload
    actual = intervention_fille.début
    assert_equal 'Remarque saisie après le scan', intervention_fille.commentaires
    assert_equal expected, actual
  end

  test 'renvoyer le formulaire sans changer les dates ne crée aucun audit sur début ni fin' do
    intervention = interventions(:tonte_locaux)

    # Changement des secondes, qui ne doit pas créer d'audit après le formulaire qui change à 0 seconde
    intervention.update_columns(début: intervention.début.change(sec: 32), fin: intervention.fin.change(sec: 32))
    
    début_avant = intervention.début
    fin_avant = intervention.fin
    audits_avant = intervention.audits.pluck(:id)

    patch intervention_url(intervention), params: {
      intervention: { début: début_avant.to_date.to_s, début_hour: début_avant.hour, début_minute: début_avant.min,
                      fin: fin_avant.to_date.to_s, fin_hour: fin_avant.hour, fin_minute: fin_avant.min }
    }

    # Derniers audits après la modification
    derniers_audits = intervention.audits.where.not(id: audits_avant).pluck(:audited_changes)
    
    # Aucun début ou fin ne doit apparaitre dans les audits
    refute derniers_audits.any? { |change| change.key?("début") || change.key?("fin") }
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un paramètre workflow_state forgé à la modification laisse l’état inchangé (critique)' do
    intervention = interventions(:nouvelle_intervention)
    état_avant = intervention.workflow_state

    patch intervention_url(intervention),
          params: { intervention: { description: intervention.description, workflow_state: 'validé' } }

    assert_equal état_avant, intervention.reload.workflow_state
  end

  test 'une note et un avis soumis par un agent laissent l’évaluation inchangée (critique)' do
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
  test 'une intervention est terminée lorsque le formulaire de terminaison est enregistré (critique)' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.terminé?
    assert_equal 'Intervention terminée', flash[:notice]
  end

  test 'le formulaire de terminaison refuse une intervention sans date de fin (critique)' do
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
  test 'le formulaire de terminaison refuse une intervention sans agent (critique)' do
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
  test 'un paramètre de terminaison forgé par un adhérent laisse l’intervention inchangée (critique)' do
    intervention = interventions(:intervention_paris)
    sign_in users(:patrick_adherent_paris)

    patch intervention_url(intervention), params: {
      terminer: 1,
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une modification sans demande de terminaison laisse l’état inchangé' do
    intervention = interventions(:intervention_paris)

    patch intervention_url(intervention), params: {
      intervention: { début: 2.hours.ago, fin: 1.hour.ago, description: intervention.description }
    }

    assert intervention.reload.nouveau?
  end

  test 'une intervention dont la description est vidée n’est pas modifiée' do
    patch intervention_url(@intervention), params: { intervention: { description: '' } }

    assert_response :unprocessable_content
    assert_not_equal '', @intervention.reload.description
  end

  test 'une photo soumise à la modification est ajoutée' do
    assert_difference('@intervention.photos.count', 1) do
      patch intervention_url(@intervention), params: {
        intervention: { photos: [fixture_file_upload('exemple.png', 'image/png')] }
      }
    end
  end

  test 'les photos ré-émises en signed_id sont conservées et la nouvelle ajoutée' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    existante = @intervention.photos.first

    patch intervention_url(@intervention), params: {
      intervention: { photos: [existante.signed_id, fixture_file_upload('exemple.png', 'image/png')] }
    }

    assert_equal 2, @intervention.reload.photos.count
  end

  test 'l’ajout d’une photo de demande laisse les photos de réalisation intactes' do
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

  test 'les photos de demande ré-émises en signed_id sont conservées et la nouvelle ajoutée' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save
    existante = @intervention.photos_demande.first

    patch intervention_url(@intervention), params: {
      intervention: { photos_demande: [existante.signed_id, fixture_file_upload('exemple.png', 'image/png')] }
    }

    assert_equal 2, @intervention.reload.photos_demande.count
  end

  test "l'ajout d'une photo de demande est tracé dans l'audit" do
    assert_difference('@intervention.audits.count', 1) do
      patch intervention_url(@intervention), params: {
        intervention: { photos_demande: [fixture_file_upload('exemple.png', 'image/png')] }
      }
    end

    assert_equal 'photo de la demande ajoutée', @intervention.audits.last.comment.sub(/\A\d+ /, '')
  end

  test "l'enregistrement du commentaire depuis le pointage statut redirige vers l'accueil" do
    intervention = interventions(:intervention_fille)

    patch intervention_url(intervention),
          params: { intervention: { commentaires: 'Terminé côté agent' },
                    commit: 'Enregistrer le commentaire' }

    assert_redirected_to root_path
    assert_equal 'Terminé côté agent', intervention.reload.commentaires
  end

  test 'une saisie a posteriori dont la fin précède le début n’est pas enregistrée' do
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

  test 'une saisie a posteriori aux dates futures n’est pas enregistrée' do
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

  test "un agent peut changer l'adhérent d'une intervention hors pointage" do
    agent = users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    sign_in agent

    patch intervention_url(intervention), params: {
      intervention: { adherent_id: users(:patrick_adherent_paris).id, description: intervention.description }
    }

    assert_equal users(:patrick_adherent_paris), intervention.reload.adherent
  end

  test "un manager peut changer l'adhérent d'une fille de pointage" do
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

  test 'une fille de pointage n’accepte pas un second agent' do
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

  test 'le formulaire réaffiché après le refus d’un second agent conserve la saisie' do
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

  test 'le formulaire réaffiché après un refus conserve les agents et les outils soumis' do
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

  test 'les outils soumis à la modification sont enregistrés' do
    sign_in users(:hidalgo)
    intervention = interventions(:nouvelle_intervention)
    outil = tools(:outil_paris)

    patch intervention_url(intervention), params: {
      intervention: { description: intervention.description, tool_ids: ['', outil.id] }
    }

    assert_equal [outil.id], intervention.reload.tool_ids
  end

  test 'l’agent d’une fille de pointage reste remplaçable' do
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

  test 'une intervention hors pointage accepte plusieurs agents' do
    sign_in users(:hidalgo)
    intervention = interventions(:nouvelle_intervention)

    patch intervention_url(intervention), params: {
      intervention: { agent_ids: ['', users(:bond).id, users(:électricité).id],
                      description: intervention.description }
    }

    assert_equal [users(:bond).id, users(:électricité).id].sort, intervention.reload.agent_ids.sort
  end

  test 'le formulaire de modification réaffiché après un refus propose les agents du service soumis' do
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

  test 'une modification par un adhérent conserve les mots clés' do
    @intervention.update!(tag_list: 'urgence, plomberie')
    sign_in users(:weil)

    patch intervention_url(@intervention),
          params: { intervention: { description: 'Description revue par l’adhérent' } }

    assert_redirected_to intervention_url(@intervention)
    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'un manager qui vide les mots clés les retire' do
    @intervention.update!(tag_list: 'urgence, plomberie')

    # Un select multiple vidé reste soumis, grâce au champ caché de Rails.
    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description, tags_manager: [''] } }

    assert_redirected_to intervention_url(@intervention)
    assert_empty @intervention.reload.tag_list
  end

  test 'un manager peut modifier les mots clés' do
    @intervention.update!(tag_list: 'urgence')

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_manager: ['', 'urgence', 'plomberie'] } }

    assert_equal %w[urgence plomberie], @intervention.reload.tag_list
  end

  test 'un agent peut modifier les mots clés' do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:bond)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_intervenant: ['', 'élagage'] } }

    assert_equal ['élagage'], @intervention.reload.tag_list
  end

  test "le champ tags_intervenant soumis par un manager est ignoré" do
    @intervention.update!(tag_list: 'urgence')

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_intervenant: ['', 'forgé'] } }

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  test "le champ tags_manager soumis par un agent est ignoré" do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:bond)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description,
                                    tags_manager: ['', 'forgé'] } }

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  # À inverser à la correction (retrait de :tag_list des permits).
  test 'un adhérent qui forge tag_list écrase les mots clés' do
    @intervention.update!(tag_list: 'urgence')
    sign_in users(:weil)

    patch intervention_url(@intervention),
          params: { intervention: { description: @intervention.description, tag_list: 'forgé' } }

    assert_equal ['forgé'], @intervention.reload.tag_list
  end

  test 'le formulaire réaffiché après un refus conserve les mots clés saisis, mot clé inédit compris' do
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

  test 'une intervention sans mouvement est supprimée' do
    assert_difference('Intervention.count', -1) do
      delete intervention_url(interventions(:nouvelle_intervention))
    end

    assert_redirected_to interventions_url
  end

  test 'une intervention avec des mouvements n’est pas supprimée' do
    assert_no_difference('Intervention.count') do
      delete intervention_url(@intervention)
    end

    assert_response :see_other # Redirection après erreur
  end

  # filet ne doit pas bloquer le parcours nominal.
  test 'le bouton Terminer termine une intervention saine' do
    agent = users(:électricité)
    intervention = cree_intervention_en_conflit(agent, avec_conflit: false)
    sign_in agent

    post terminer_intervention_url(intervention)

    assert intervention.reload.terminé?
  end

  # ==================== TESTS CRITIQUES ====================

  # le chemin de terminaison, sans qu'aucun formulaire ne le fournisse.
  test 'le bouton Terminer enregistre le temps total et une pause à 0 (critique)' do
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

  test 'le bouton Terminer refuse une intervention sans agent (critique)' do
    intervention = interventions(:intervention_paris)
    intervention.agents.destroy_all

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Au moins un agent est obligatoire/, flash[:alert])
    assert intervention.reload.nouveau?, "l'état ne doit pas avoir changé"
  end

  # Test critique — parcours quotidien de l'agent : terminer son intervention.
  test 'le bouton Terminer sur une intervention en conflit redirige avec une alerte au lieu d’une erreur (critique)' do
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

  test 'le bouton Terminer refuse une intervention déjà validée' do
    intervention = cree_intervention_validee

    post terminer_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/Impossible de terminer/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  # ==================== TESTS CRITIQUES ====================

  # Test critique — parcours quotidien : l'adhérent valide le travail terminé.
  test 'l’adhérent valide une intervention terminée (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, "l'intervention doit passer à l'état validé"
  end

  # re-valider une intervention déjà validée.
  test 'une seconde validation d’une intervention déjà validée redirige sans erreur (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)
    post valider_intervention_url(intervention)

    post valider_intervention_url(intervention) # 2e clic : plus en état terminé

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.validé?, 'le double-clic ne doit rien casser'
  end

  # Même filet côté adhérent, sur les deux transitions qu'il déclenche.
  test 'valider une intervention en conflit redirige avec une alerte au lieu d’une erreur (critique)' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'terminé')
    sign_in users(:weil)

    post valider_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  # Test critique — parcours quotidien : l'adhérent refuse le travail terminé.
  test 'l’adhérent refuse une intervention terminée (critique)' do
    intervention = interventions(:intervention_terminée)
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert intervention.reload.refusé?, "l'intervention doit passer à l'état refusé"
  end

  test 'refuser une intervention en conflit redirige avec une alerte au lieu d’une erreur (critique)' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'terminé')
    sign_in users(:weil)

    post refuser_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_match(/pas valide/, flash[:alert])
    assert intervention.reload.terminé?, "l'état ne doit pas avoir changé"
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une intervention validée est archivée' do
    intervention = cree_intervention_validee

    post archiver_intervention_url(intervention)

    assert_redirected_to intervention_url(intervention)
    assert_equal 'archivé', intervention.reload.workflow_state
  end

  test 'archiver une intervention déjà archivée est signalé par une alerte' do
    intervention = cree_intervention_validee
    intervention.update_columns(workflow_state: 'archivé')

    post archiver_intervention_url(intervention)

    assert_match(/déjà archivée/i, flash[:alert].to_s)
  end

  test 'une intervention à l’état nouveau ne peut pas être archivée' do
    intervention = interventions(:nouvelle_intervention)

    post archiver_intervention_url(intervention)

    assert_match(/ne peut pas se archiver/i, flash[:alert].to_s)
    assert_equal 'nouveau', intervention.reload.workflow_state
  end

  test 'une intervention invalide n’est pas archivée et le motif est affiché' do
    intervention = cree_intervention_en_conflit(users(:électricité), workflow_state: 'validé')

    post archiver_intervention_url(intervention)

    assert_match(/n'est pas valide/i, flash[:alert].to_s)
    assert_equal 'validé', intervention.reload.workflow_state
  end

  test 'un manager peut supprimer une photo' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to @intervention
  end

  test "un agent affecté à l'intervention peut supprimer une photo" do
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

  test 'une photo supprimée est réellement effacée, blob détruit et fichier retiré du stockage' do
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

  test "la suppression d'une photo est tracée dans l'audit" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    photo_id = @intervention.photos.first.id

    assert_difference('@intervention.audits.count', 1) do
      delete purge_intervention_url(@intervention), params: { photo_id: photo_id }
    end

    assert_equal 'Photo supprimée', @intervention.audits.last.comment
  end

  test "l'adhérent de l'intervention peut supprimer une photo (épinglage : purge? = show?)" do
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

  test 'la suppression d’une photo inexistante répond introuvable sans rien supprimer' do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: { photo_id: 0 }
    end

    assert_response :not_found
  end

  test "la photo d'une autre intervention ne peut pas être supprimée depuis celle-ci" do
    autre = interventions(:nouvelle_intervention)
    autre.photos.attach(file_fixture('exemple.png'))
    autre.save
    cible = autre.photos.first

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purge_intervention_url(@intervention), params: { photo_id: cible.id }
    end

    assert_response :not_found
  end

  test 'la suppression d’une photo redirige avec le statut attendu par Turbo' do
    # 303 après
    # toute soumission destructrice Turbo, comme le reste de l'app.
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save

    delete purge_intervention_url(@intervention), params: {
      photo_id: @intervention.photos.first.id
    }

    assert_response :see_other
  end

  test 'un manager peut supprimer une photo de demande' do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save

    assert_difference('@intervention.photos_demande.count', -1) do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end

    assert_redirected_to @intervention
  end

  test 'une photo de demande supprimée est réellement effacée, blob détruit et fichier retiré du stockage' do
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

  test 'supprimer une photo de demande laisse les photos de réalisation intactes' do
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

  test "un agent affecté à l'intervention peut supprimer une photo de réalisation" do
    @intervention.photos.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:bond)

    assert_difference('@intervention.photos.count', -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end
  end

  test 'la suppression des photos est cloisonnée par type de photo' do
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

  test "l'adhérent de l'intervention peut supprimer une photo de demande" do
    @intervention.photos_demande.attach(file_fixture('exemple.png'))
    @intervention.save
    sign_in users(:weil)

    assert_difference('@intervention.photos_demande.count', -1) do
      delete purger_photos_demande_intervention_url(@intervention), params: {
        photo_id: @intervention.photos_demande.first.id
      }
    end
  end

  test "la photo de demande d'une autre intervention ne peut pas être supprimée depuis celle-ci" do
    autre = interventions(:nouvelle_intervention)
    autre.photos_demande.attach(file_fixture('exemple.png'))
    autre.save
    cible = autre.photos_demande.first

    assert_no_difference('ActiveStorage::Attachment.count') do
      delete purger_photos_demande_intervention_url(@intervention), params: { photo_id: cible.id }
    end

    assert_response :not_found
  end

  test 'le pointage d’un modèle crée une fille' do
    # Le sign_in gère tout seul la déconnexion du premier sign_in dans le setup
    sign_in users(:martin_technique_paris)

    intervention = interventions(:intervention_repete)

    assert_difference('Intervention.count', 1) do
      get pointer_intervention_url(intervention)
    end
  end

  test "le pointage d'un agent absent aujourd'hui est refusé avec le motif" do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0)

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(interventions(:intervention_repete))
    end

    assert_redirected_to intervention_path(interventions(:intervention_repete))
    assert_match 'Agent(s) indisponible(s)', flash[:alert]
  end

  test "le pointage de l'après-midi est accepté lorsque l'agent n'est absent que le matin" do
    agent = users(:martin_technique_paris)
    sign_in agent
    Absence.create!(user: agent, du: Date.today, au: Date.today, motif: 0, matin: true)

    travel_to Time.current.change(hour: 14) do
      assert_difference('Intervention.count', 1) do
        get pointer_intervention_url(interventions(:intervention_repete))
      end
    end
  end

  test 'le pointage d’un modèle déjà pointé termine la fille' do
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

  test 'le pointage de début enregistre l’instant exact du scan' do
    sign_in users(:bond)
    modele = interventions(:intervention_repete)
    scan = Time.current.middle_of_day.change(sec: 12)

    travel_to scan do
      get pointer_intervention_url(modele)
    end

    assert_equal scan, Intervention.find_by(template_slug: modele.slug).début
  end

  test 'le pointage de fin enregistre l’instant exact du scan' do
    sign_in users(:bond)
    modele = interventions(:intervention_repete)
    scan_de_fin = Time.current.middle_of_day.change(sec: 41)

    travel_to Time.current.middle_of_day.change(sec: 12) do
      get pointer_intervention_url(modele)
    end
    travel_to scan_de_fin do
      get pointer_intervention_url(modele)
    end

    assert_equal scan_de_fin, Intervention.find_by(template_slug: modele.slug).fin
  end

  test 'terminer un pointage en saisissant sa date de fin laisse sa date de début inchangée' do
    sign_in users(:bond)
    scan_time = Time.current.change(sec: 27) - 2.hour

    modele = interventions(:intervention_repete)

    travel_to scan_time do
      get pointer_intervention_url(modele)
    end

    intervention_fille = Intervention.reorder(created_at: :desc).where(template_slug: modele.slug).first

    expected_début = intervention_fille.début
    fin_saisie = scan_time + 2.hours
    expected_fin = fin_saisie.change(sec: 0)

    travel_to fin_saisie do
      patch intervention_url(intervention_fille), params: {
        terminer: 1,
        intervention: {
          début: expected_début.to_date.to_s,
          début_hour: expected_début.hour, début_minute: expected_début.min,
          fin: fin_saisie.to_date.to_s,
          fin_hour: fin_saisie.hour, fin_minute: fin_saisie.min,
          temps_de_pause: 0
        }
      }
    end

    intervention_fille.reload
    actual_début = intervention_fille.début
    actual_fin = intervention_fille.fin
    assert_equal expected_début, actual_début
    assert_equal expected_fin, actual_fin
  end

  test "le pointage d'une intervention qui n'est pas un modèle ne crée aucune fille" do
    intervention = interventions(:intervention_repete)
    intervention.repeter = false
    intervention.save

    assert_no_difference('Intervention.count') do
      get pointer_intervention_url(intervention)
    end
  end

  test 'le pointage d’un modèle à plusieurs agents crée une fille par agent' do
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

  test "un pointage dont l'enregistrement échoue affiche l'erreur au lieu d'une page introuvable" do
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
  test "le pointage sur une fille close restée à l'état nouveau enregistre une reprise d'activité" do
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

  test "le pointage d'une intervention qui n'est pas un modèle est refusé avec une alerte" do
    intervention = interventions(:nouvelle_intervention) # bond y est agent affecté
    sign_in users(:bond)

    get pointer_intervention_url(intervention)

    assert_match(/n'est pas un modèle de pointage/i, flash[:alert].to_s)
  end

  test 'le second scan termine la fille, état terminé et fin renseignée' do
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

  test 'plusieurs scans dans la journée créent plusieurs filles' do
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

  test 'le statut de pointage d’un modèle redirige vers la fille du pointeur' do
    sign_in users(:martin_technique_paris)
    modele = interventions(:intervention_repete)

    # On crée d'abord une fille (clock in) pour que la redirection ait une cible.
    get pointer_intervention_url(modele)

    get pointage_statut_intervention_url(modele)
    assert_response :redirect
  end

  test 'la géolocalisation d’une fille de pointage est enregistrée' do
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

  test 'la géolocalisation d’une intervention invalide est refusée avec ses erreurs' do
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

  test 'un agent occupé sur les dates réelles est renvoyé indisponible' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'un agent occupé sur des dates réelles disjointes n’est pas renvoyé indisponible' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'un agent dont le réel est disjoint mais le prévu chevauchant n’est pas renvoyé indisponible' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00',
                                début_prévue: '2025-04-08 14:00', fin_prévue: '2025-04-08 17:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'les disponibilités se replient sur les dates prévues lorsque le réel est absent' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début_prévue: '2025-04-08 09:00', fin_prévue: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut_prevue: '2025-04-08 10:00',
                                     date_fin_prevue: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'des bornes mixtes réelle et prévue détectent le conflit' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 10:30', date_fin_prevue: '2025-04-08 11:30')

    assert_includes json['agents'], users(:bond).id
  end

  test 'le réel prime sur le prévu borne par borne et aucun conflit n’est détecté' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites(date_debut: '2025-04-08 13:00',
                                     date_debut_prevue: '2025-04-08 10:30',
                                     date_fin: '2025-04-08 14:00')

    assert_not_includes json['agents'], users(:bond).id
  end

  test 'un outil occupé sur la plage est renvoyé indisponible' do
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

  test 'un agent absent sur la plage est renvoyé indisponible' do
    sign_in users(:administrateur_paris)
    Absence.create!(du: '2025-04-08', au: '2025-04-08', motif: 0, user: users(:bond))

    json = interroger_disponibilites(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], users(:bond).id
  end

  test 'les disponibilités sans aucune date répondent vide sans erreur' do
    sign_in users(:administrateur_paris)
    cree_intervention_occupante(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger_disponibilites

    assert_empty json['agents']
    assert_empty json['tools']
  end

  test 'les services d’un adhérent sont retournés en JSON' do
    get services_for_adherent_interventions_url(adherent_id: users(:weil).id)

    assert_response :success
    noms = response.parsed_body.map { |service| service['nom'] }
    assert_includes noms, services(:informatique).nom
  end

  test 'aucun service n’est retourné pour un adhérent hors périmètre' do
    get services_for_adherent_interventions_url(adherent_id: users(:adherent_marseille).id)

    assert_response :success
    assert_empty response.parsed_body
  end

  test 'un adhérent inconnu répond introuvable sans planter' do
    get services_for_adherent_interventions_url(adherent_id: 0)

    assert_response :not_found
  end

  test 'les agents d’un service sont retournés en JSON' do
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

  test 'les agents d’un service hors périmètre ne sont pas retournés et le résultat se replie sur le périmètre' do
    # service_marseille est hors du périmètre de hidalgo : on ne fuite pas ses agents
    get agents_for_service_interventions_url(service_id: services(:service_marseille).id), as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_not_includes ids, users(:agent_marseille).id
    # Service hors périmètre ⇒ repli sur tous les agents du current_user
    assert_includes ids, users(:martin_technique_paris).id
  end

  test 'sans service, tous les agents du périmètre sont retournés' do
    get agents_for_service_interventions_url, as: :json

    assert_response :success
    ids = response.parsed_body.map { |a| a['id'] }

    assert_includes ids, users(:martin_technique_paris).id
    assert_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'le formulaire de création d’un modèle de pointage prépare une intervention répétée' do
    get new_intervention_modele_pointage_interventions_url

    assert_response :success
    assert assigns(:intervention).repeter
  end

  test "un modèle de pointage est créé à l'état pointage activé lorsque les paramètres sont valides" do
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

  test 'un modèle de pointage sans description n’est pas créé' do
    assert_no_difference('Intervention.count') do
      post create_intervention_modele_pointage_interventions_url,
           params: { intervention: { description: '' } }
    end

    assert_response :unprocessable_content
  end

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
