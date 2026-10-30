# frozen_string_literal: true

require 'test_helper'

class DashboardDonneesTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.current.change(hour: 12)
  end

  test 'le tableau de bord d’un manager cumule le temps par service' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_in_delta 17.0, assigns(:temps_total_par_service)['Technique']
  end

  test 'le tableau de bord d’un manager répartit le temps par agent' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: mois(3), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_in_delta 6.0, assigns(:temps_total_par_agent)['Martin Michel']
  end

  test 'le tableau de bord d’un manager cumule le temps par adhérent' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: mois(3))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_in_delta 17.0, assigns(:temps_total_par_adherent)['Weil Ariel']
  end

  test 'les indicateurs d’un manager ne comptent que la période affichée' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(5, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 3, 15, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-02-28')

    assert_in_delta 8.0, assigns(:temps_total_par_service)['Technique']
  end

  test 'le temps par adhérent d’un manager ne compte que la période affichée' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(5, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 3, 15, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-02-28')

    assert_in_delta 8.0, assigns(:temps_total_par_adherent)['Weil Ariel']
  end

  test 'le temps par adhérent d’un manager est trié du plus chargé au moins chargé' do
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(6, adherent: users(:berthout), service: services(:technique), debut: Time.zone.local(2023, 1, 16, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_equal [users(:berthout).nom_prénom, 'Weil Ariel'], assigns(:temps_total_par_adherent).keys.first(2)
  end

  test 'le temps par agent d’un manager ne compte que la période affichée' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 3, 15, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-02-28')

    assert_in_delta 6.0, assigns(:temps_total_par_agent)['Martin Michel']
  end

  test 'le temps par agent d’un manager inclut les managers et administrateurs affectés' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:administrateur_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 2.0, assigns(:temps_total_par_agent)[users(:administrateur_paris).nom_prénom]
  end

  test 'le temps par agent d’un manager inclut un administrateur affecté hors de ses services' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:philippe_super_admin))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 2.0, assigns(:temps_total_par_agent)[users(:philippe_super_admin).nom_prénom]
  end

  test 'le temps par agent d’un manager est trié du plus chargé au moins chargé' do
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:bond))
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_equal ['Martin Michel', users(:bond).nom_prénom], assigns(:temps_total_par_agent).keys.first(2)
  end

  test 'le graphe des états par mois n’a de série ni pour les modèles de pointage ni pour les interventions archivées' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_equal %w[Nouveau Terminé Validé Refusé], assigns(:data_workflow_chart)[:datasets].map { |serie| serie[:label] }
  end

  test 'une intervention prévue et non commencée compte dans le mois de son début prévu' do
    cree_intervention_prevue(Time.zone.local(2023, 2, 10, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-02-01', au: '2023-02-28')

    assert_equal 1, assigns(:donnees_graphes)[:etats]['Technique']['2023-02'][Intervention::NOUVEAU]
  end

  test 'l’empreinte CO₂ d’un manager est arrondie à deux décimales' do
    intervention = cree_intervention_avec_temps(1, adherent: users(:weil), service: services(:technique),
                                                   debut: Time.zone.local(2023, 1, 15, 9))
    intervention.update_columns(co2: 1.2345678)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 1.23, assigns(:co2_total_par_mois)['2023-01'], 0.0001
  end

  test 'l’activité des agents d’un manager lit le temps d’un agent dans la vue, comme le temps par agent exporté' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 3, 15, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-02-28')

    assert_in_delta 6.0, ligne_agent(users(:martin_technique_paris))[:temps]
    assert_in_delta assigns(:temps_total_par_agent)['Martin Michel'], ligne_agent(users(:martin_technique_paris))[:temps]
  end

  test 'l’activité des agents compte les pointages, mais ni les modèles de pointage ni les interventions nouvelles' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:bond))
      .update_columns(template_slug: 'tonte-hebdomadaire')
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:bond))
      .update_columns(workflow_state: Intervention::POINTAGE_ACTIVE)
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 17, 9), agent: users(:bond))
      .update_columns(workflow_state: Intervention::NOUVEAU)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_equal 1, ligne_agent(users(:bond))[:nb]
    assert_equal 1, ligne_agent(users(:bond))[:pointages]
  end

  test 'l’activité des agents donne la part d’interventions validées et la note moyenne des interventions validées ou refusées notées' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:bond))
      .update_columns(note: 4)
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:bond))
      .update_columns(note: 0)
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 17, 9), agent: users(:bond))
      .update_columns(workflow_state: Intervention::REFUSE, note: 2)
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 18, 9), agent: users(:bond))
      .update_columns(workflow_state: Intervention::TERMINE)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_equal [4, 2, 1, 1, 0], ligne_agent(users(:bond)).values_at(:nb, :validees, :refusees, :terminees, :archivees)
    assert_in_delta 3.0, ligne_agent(users(:bond))[:note]
    assert_equal 2, ligne_agent(users(:bond))[:avis]
  end

  test 'l’activité des agents ne note pas un agent dont aucune intervention n’a été notée' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:bond))
      .update_columns(workflow_state: Intervention::TERMINE)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_nil ligne_agent(users(:bond))[:note]
    assert_equal 0, ligne_agent(users(:bond))[:avis]
  end

  # ==================== TESTS CRITIQUES ====================
  # Le filtre de service propre à la carte ne doit ni sortir du périmètre du manager ni toucher les autres cartes.
  test 'l’activité des agents est restreinte au service choisi pour la seule carte (critique)' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:patrick_adherent_paris), service: services(:service_paris),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:agent_whatsapp))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31', agents_service: 'Technique')

    assert_equal 'Technique', assigns(:activite_agents)[:service]
    assert_in_delta 6.0, ligne_agent(users(:martin_technique_paris))[:temps]
    assert_nil ligne_agent(users(:agent_whatsapp))
    assert_in_delta 3.0, assigns(:temps_total_par_agent)[users(:agent_whatsapp).nom_prénom]
  end

  test 'un service hors périmètre demandé pour l’activité des agents est ignoré (critique)' do
    cree_intervention_avec_temps(3, adherent: users(:patrick_adherent_paris), service: services(:service_paris),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:agent_whatsapp))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31', agents_service: services(:comptabilite).nom)

    assert_nil assigns(:activite_agents)[:service]
    assert_in_delta 3.0, ligne_agent(users(:agent_whatsapp))[:temps]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'l’activité des agents est restreinte aux derniers mois choisis pour la seule carte' do
    travel_to Time.zone.local(2023, 7, 15, 12)
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 6, 15, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-06-30', agents_periode: 3)

    assert_equal %w[2023-04 2023-05 2023-06], assigns(:activite_agents)[:mois]
    assert_equal 3, assigns(:activite_agents)[:periode]
    assert_in_delta 3.0, ligne_agent(users(:martin_technique_paris))[:temps]
    assert_in_delta 9.0, assigns(:temps_total_par_agent)['Martin Michel']
  end

  test 'les derniers mois de l’activité des agents retombent sur la période affichée quand ils ne sont pas proposés' do
    travel_to Time.zone.local(2023, 7, 15, 12)
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-02-28', agents_periode: 12)

    assert_nil assigns(:activite_agents)[:periode]
    assert_equal %w[2023-01 2023-02], assigns(:activite_agents)[:mois]
    assert_in_delta 6.0, ligne_agent(users(:martin_technique_paris))[:temps]
  end

  test 'l’activité des agents inclut les managers et administrateurs intervenants, un administrateur hors services compris' do
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:hidalgo))
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:philippe_super_admin))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 2.0, ligne_agent(users(:hidalgo))[:temps]
    assert_in_delta 2.0, ligne_agent(users(:philippe_super_admin))[:temps]
  end

  test 'l’activité des agents est rangée du plus de temps au moins, les agents sans activité en dernier' do
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:bond))
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    lignes = assigns(:activite_agents)[:lignes]
    assert_equal [users(:martin_technique_paris), users(:bond)], lignes.map { |ligne| ligne[:agent] }.first(2)
    assert_equal 0, lignes.last[:temps]
  end

  test 'l’activité des agents se range par la colonne demandée' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
      .update_columns(note: 4)
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:martin_technique_paris))
      .update_columns(workflow_state: Intervention::REFUSE, note: 0)
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 17, 9), agent: users(:bond))
    refresh_dashboard_views!
    sign_in users(:hidalgo)
    bond = users(:bond)
    martin = users(:martin_technique_paris)

    { 'agents.nom' => [bond, martin], 'agents.temps' => [bond, martin], 'agents.interventions' => [bond, martin],
      'agents.validees' => [martin, bond], 'agents.note' => [martin, bond] }.each do |colonne, (premier, second)|
      get dashboard_url(du: '2023-01-01', au: '2023-01-31', column: colonne, direction: 'asc')

      agents = assigns(:activite_agents)[:lignes].map { |ligne| ligne[:agent] }
      assert_operator agents.index(premier), :<, agents.index(second), colonne
    end
  end

  test 'la courbe de l’activité des agents a une tranche par mois sur une période de douze mois' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 3, 15, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-12-31')

    assert_equal 12, assigns(:activite_agents)[:tranches].size
    assert_equal 'jan. 2023', assigns(:activite_agents)[:tranches].first
    assert_equal [6.0, 0.0, 3.0] + [0.0] * 9, ligne_agent(users(:martin_technique_paris))[:temps_courbe]
    assert_equal [1, 0, 1] + [0] * 9, ligne_agent(users(:martin_technique_paris))[:nb_courbe]
  end

  test 'la courbe de l’activité des agents découpe une période plus courte en douze tranches de jours' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 2, 20, 9), agent: users(:martin_technique_paris))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-02-28')

    assert_equal 12, assigns(:activite_agents)[:tranches].size
    assert_equal '1 – 4 jan.', assigns(:activite_agents)[:tranches].first
    assert_equal 6.0, ligne_agent(users(:martin_technique_paris))[:temps_courbe][3]
    assert_equal 3.0, ligne_agent(users(:martin_technique_paris))[:temps_courbe][10]
    assert_equal 2, ligne_agent(users(:martin_technique_paris))[:nb_courbe].sum
  end

  test 'le tableau de bord d’un agent ne porte pas l’activité des agents' do
    sign_in users(:bond)

    get dashboard_url

    assert_nil assigns(:activite_agents)
  end

  test 'l’activité par jour d’un manager compte les interventions et leur temps, celles d’un jour à venir pesant leur durée prévue par agent' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2022, 2, 10, 9))
    cree_intervention_avec_temps(2, adherent: users(:weil), service: services(:informatique), debut: Time.zone.local(2022, 2, 10, 14))
    cree_intervention_prevue(Time.zone.local(2022, 2, 1, 9))
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Audit planifié',
                         workflow_state: Intervention::NOUVEAU, agents: [users(:hidalgo), users(:administrateur_paris)],
                         début_prévue: Time.zone.local(2022, 5, 11, 9), fin_prévue: Time.zone.local(2022, 5, 11, 11))
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_equal({ '2022-02-01' => [1, 0.0], '2022-02-10' => [2, 8.0], '2022-05-11' => [1, 4.0] }, assigns(:donnees_graphes)[:activite])
  end

  test 'l’activité par jour d’un manager couvre l’année en cours, quelle que soit la période affichée' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2022, 2, 10, 9))
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2021, 12, 31, 9))
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_equal({ '2022-02-10' => [1, 6.0] }, assigns(:donnees_graphes)[:activite])
  end

  test 'l’activité par jour d’un manager ignore les modèles de pointage' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Pointage du site', repeter: true,
                         début_prévue: Time.zone.local(2022, 5, 11, 8), fin_prévue: Time.zone.local(2022, 5, 11, 18))
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_empty assigns(:donnees_graphes)[:activite]
  end

  test 'l’activité par jour d’un manager porte l’année demandée' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2021, 12, 31, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, annee: 2021)

    assert_equal 2021, assigns(:annee)
    assert_equal({ '2021-12-31' => [1, 4.0] }, assigns(:donnees_graphes)[:activite])
  end

  test 'une année sans statistique est remplacée par l’année en cours' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    sign_in users(:hidalgo)

    get dashboard_url(annee: 1999)

    assert_equal 2022, assigns(:annee)
  end

  test 'les années proposées vont de la première statistique à l’année en cours' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2021, 12, 31, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal 2021, assigns(:annees).first
    assert_includes assigns(:annees), 2022
  end

  # ==================== TESTS CRITIQUES ====================
  # Le filtre par service borne le tableau de bord au périmètre de services de l'utilisateur.
  test 'le filtre par service restreint les indicateurs d’un manager à ce service (critique)' do
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:bond))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31', service: [services(:informatique).id])

    assert_equal({ 'Informatique' => 1 }, assigns(:qte_interventions_par_service))
    assert_in_delta 4.0, assigns(:temps_total_par_adherent)['Weil Ariel']
    assert_not_includes assigns(:temps_total_par_agent).keys, users(:bond).nom_prénom
  end

  test 'un service hors du périmètre d’un manager est ignoré et tout son périmètre reste affiché (critique)' do
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 16, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31', service: [services(:service_marseille).id])

    assert_equal({ 'Informatique' => 1, 'Service_Paris' => 0, 'Technique' => 1 }, assigns(:qte_interventions_par_service))
    assert_empty assigns(:selected_service_ids)
  end

  test 'le filtre par service d’un manager ne propose que ses services (critique)' do
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal [services(:informatique), services(:service_paris), services(:technique)], assigns(:services).to_a
  end

  test 'le filtre par service d’un administrateur propose tous les services de son organisation, les siens présélectionnés (critique)' do
    sign_in users(:administrateur_paris)

    get dashboard_url

    assert_includes assigns(:services), services(:menage)
    assert_equal users(:administrateur_paris).service_ids.sort, assigns(:selected_service_ids).sort
  end

  test 'un service sélectionné sans intervention sur la période apparaît à zéro dans l’export d’un manager (critique)' do
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique),
                                    debut: Time.zone.local(2023, 1, 15, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31',
                      service: [services(:informatique).id, services(:technique).id])

    assert_equal({ 'Informatique' => 1, 'Technique' => 0 }, assigns(:qte_interventions_par_service))
    assert_equal %w[Informatique Technique], assigns(:temps_total_par_service).keys
    assert_equal 0, assigns(:temps_total_par_service)['Technique']
  end

  test 'le filtre par service restreint l’activité par jour d’un manager à ce service (critique)' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique), debut: Time.zone.local(2022, 2, 10, 9))
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2022, 2, 10, 14))
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, service: [services(:informatique).id])

    assert_equal({ '2022-02-10' => [1, 4.0] }, assigns(:donnees_graphes)[:activite])
  end

  test 'l’activité par jour d’un manager est bornée à ses services (critique)' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    cree_intervention_avec_temps(1, adherent: users(:george_lucas), service: services(:comptabilite), debut: Time.zone.local(2022, 2, 10, 9))
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls)

    assert_empty assigns(:donnees_graphes)[:activite]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'l’export du tableau de bord d’un adhérent porte le temps consommé et le temps restant de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url(format: :xls)

    assert_in_delta 6.0, assigns(:proportion_temps_consomme)['temps_consomme']
    assert_in_delta 94.0, assigns(:proportion_temps_consomme)['temps_restant']
  end

  test 'le temps total exporté d’un adhérent est celui de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url(format: :xls)

    assert_equal '6.0h', assigns(:kpi_temps_total)
  end

  test 'le temps par service exporté d’un adhérent est celui de son service' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url(format: :xls)

    assert_in_delta 6.0, assigns(:temps_total_par_service)['Informatique']
  end

  test 'le temps par mois exporté d’un adhérent vaut 0 sur un mois sans intervention' do
    cree_donnees_adherent_informatique
    sign_in users(:adhérent_sans_intervention)

    get dashboard_url(format: :xls)

    data = assigns(:temps_total_par_mois)
    assert_in_delta 6.0, data[mois(2).strftime('%Y-%m')]
    assert_in_delta 0.0, data[mois(1).strftime('%Y-%m')]
  end

  test 'les indicateurs exportés d’un adhérent ne comptent que la période affichée' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(5, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 3, 15, 9))
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-02-28')

    data = assigns(:temps_total_par_mois)
    assert_equal '8.0h', assigns(:kpi_temps_total)
    assert_equal %w[2023-01 2023-02], data.keys
    assert_in_delta 8.0, data['2023-01']
    assert_in_delta 0.0, data['2023-02']
  end

  test 'les agents assignés exportés d’un adhérent comptent les intervenants de ses services et les administrateurs de l’organisation' do
    sign_in users(:weil)

    get dashboard_url(format: :xls)

    assert_equal User.intervenants_pour(users(:weil).services).count, assigns(:kpi_agents_actifs)
  end

  test 'l’empreinte CO₂ exportée d’un adhérent est arrondie à deux décimales' do
    intervention = cree_intervention_avec_temps(1, adherent: users(:weil), service: services(:technique),
                                                   debut: Time.zone.local(2023, 1, 15, 9))
    intervention.update_columns(co2: 1.2345678)
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31')

    assert_equal '1.23 kg', assigns(:kpi_co2_total)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le filtre par service borne le tableau de bord au périmètre de services de l'adhérent.
  test 'le filtre par service restreint les indicateurs exportés d’un adhérent à ce service (critique)' do
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 16, 9))
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31', service: [services(:informatique).id])

    assert_equal({ 'Informatique' => 1 }, assigns(:qte_interventions_par_service))
    assert_in_delta 4.0, assigns(:proportion_temps_consomme)['temps_consomme']
  end

  test 'le filtre par service d’un adhérent ne propose que ses services (critique)' do
    sign_in users(:weil)

    get dashboard_url

    assert_equal [services(:informatique), services(:technique)], assigns(:services).to_a
  end

  test 'un service sélectionné sans intervention sur la période apparaît à zéro dans l’export d’un adhérent (critique)' do
    cree_intervention_avec_temps(4, adherent: users(:weil), service: services(:informatique),
                                    debut: Time.zone.local(2023, 1, 15, 9))
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(format: :xls, du: '2023-01-01', au: '2023-01-31',
                      service: [services(:informatique).id, services(:technique).id])

    assert_equal({ 'Informatique' => 1, 'Technique' => 0 }, assigns(:qte_interventions_par_service))
    assert_equal %w[Informatique Technique], assigns(:temps_total_par_service).keys
    assert_equal 0, assigns(:temps_total_par_service)['Technique']
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le tableau de bord couvre par défaut l’année en cours' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal Date.new(2022, 1, 1), assigns(:du)
    assert_equal Date.new(2022, 12, 31), assigns(:au)
    assert_equal({ libellé: 'Année en cours', du: Date.new(2022, 1, 1), au: Date.new(2022, 12, 31) }, assigns(:periodes).first)
    assert_equal %w[2022-01-01 2022-12-31], assigns(:donnees_graphes).values_at(:du, :au)
  end

  test 'la période demandée est étendue aux mois entiers' do
    sign_in users(:hidalgo)

    get dashboard_url(format: :xls, du: '2023-01-10', au: '2023-02-20')

    assert_equal Date.new(2023, 1, 1), assigns(:du)
    assert_equal Date.new(2023, 2, 28), assigns(:au)
    assert_equal %w[2023-01 2023-02], assigns(:data_workflow_chart)[:labels]
  end

  test 'une date illisible est remplacée par la borne par défaut' do
    travel_to Time.zone.local(2022, 3, 15, 12)
    sign_in users(:hidalgo)

    get dashboard_url(du: 'hier', au: '2023-02-20')

    assert_response :success
    assert_equal Date.new(2022, 1, 1), assigns(:du)
    assert_equal Date.new(2023, 2, 28), assigns(:au)
  end

  test 'une période dont le début suit la fin est affichée sans erreur' do
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-03-01', au: '2023-01-31')

    assert_response :success
  end

  test 'le préréglage « Tout » d’un manager court du premier au dernier mois de ses statistiques' do
    cree_intervention_avec_temps(1, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2019, 5, 15, 9))
    cree_intervention_prevue(Time.zone.local(2031, 8, 10, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal({ libellé: 'Tout', du: Date.new(2019, 5, 1), au: Date.new(2031, 8, 31) }, assigns(:periodes).last)
  end

  test 'le préréglage « Tout » d’un manager ignore les statistiques des services hors de son périmètre (critique)' do
    cree_intervention_avec_temps(1, adherent: users(:george_lucas), service: services(:comptabilite), debut: Time.zone.local(2015, 5, 15, 9))
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url

    assert_operator assigns(:periodes).last[:du], :>, Date.new(2015, 5, 1)
  end

  # ==================== TESTS CRITIQUES ====================
  # Les montants du CRM touchent à l'argent et au cloisonnement : par mois de saisie et par service pour un manager,
  # ses seuls documents pour un adhérent.
  test 'les montants du CRM d’un manager sont sommés par mois de saisie et par service, aux règles du chiffre d’affaires (critique)' do
    Cotation.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Devis envoyé',
                     workflow_state: Cotation::ENVOYE, total_ht: 500, created_at: Time.zone.local(2023, 1, 10, 9))
    Cotation.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Devis brouillon',
                     workflow_state: Cotation::CREE, total_ht: 999, created_at: Time.zone.local(2023, 1, 12, 9))
    Commande.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Commande validée',
                     workflow_state: Commande::VALIDE, total_ht: 400, created_at: Time.zone.local(2023, 2, 5, 9))
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture envoyée',
                    workflow_state: Facture::ENVOYE, total_ht: 200, created_at: Time.zone.local(2023, 2, 20, 9))
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture refusée',
                    workflow_state: Facture::REFUSE, total_ht: 999, created_at: Time.zone.local(2023, 2, 21, 9))
    Facture.create!(adherent: users(:weil), service: services(:informatique), intitulé: 'Facture informatique',
                    workflow_state: Facture::VALIDE, total_ht: 50, created_at: Time.zone.local(2023, 2, 22, 9))
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-02-28')

    crm = assigns(:donnees_graphes)[:crm]
    assert_equal({ devis: 500.0, commandes: 0, factures: 0 }, crm['Technique']['2023-01'])
    assert_equal({ devis: 0, commandes: 400.0, factures: 200.0 }, crm['Technique']['2023-02'])
    assert_equal({ devis: 0, commandes: 0, factures: 50.0 }, crm['Informatique']['2023-02'])
  end

  test 'les montants du CRM d’un adhérent ne portent que ses propres documents (critique)' do
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture de Weil',
                    workflow_state: Facture::VALIDE, total_ht: 150, created_at: Time.zone.local(2023, 1, 10, 9))
    Facture.create!(adherent: users(:berthout), service: services(:technique), intitulé: 'Facture de Berthout',
                    workflow_state: Facture::VALIDE, total_ht: 999, created_at: Time.zone.local(2023, 1, 11, 9))
    sign_in users(:weil)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 150.0, assigns(:donnees_graphes)[:crm]['Technique']['2023-01'][:factures]
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==================== TESTS CRITIQUES ====================
  # Le tableau de bord d'un adhérent ne porte que ses interventions : les agents qui y sont affectés, leur temps sur
  # celles-ci seulement, et ses seules conventions.
  test 'l’activité des agents d’un adhérent ne compte que ses interventions et les agents qui y sont affectés (critique)' do
    cree_intervention_avec_temps(6, adherent: users(:weil), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(4, adherent: users(:berthout), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 16, 9), agent: users(:martin_technique_paris))
    cree_intervention_avec_temps(3, adherent: users(:berthout), service: services(:technique),
                                    debut: Time.zone.local(2023, 1, 17, 9), agent: users(:bond))
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_equal [users(:martin_technique_paris)], assigns(:activite_agents)[:lignes].map { |ligne| ligne[:agent] }
    assert_in_delta 6.0, ligne_agent(users(:martin_technique_paris))[:temps]
    assert_equal 1, ligne_agent(users(:martin_technique_paris))[:nb]
    assert_in_delta 6.0, ligne_agent(users(:martin_technique_paris))[:temps_courbe].sum
  end

  test 'le temps d’un agent sur les interventions d’un adhérent est réparti entre les agents affectés (critique)' do
    intervention = cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique),
                                                   debut: Time.zone.local(2023, 1, 15, 9), agent: users(:martin_technique_paris))
    AgentIntervention.create!(agent: users(:bond), intervention: intervention)
    refresh_dashboard_views!
    sign_in users(:weil)

    get dashboard_url(du: '2023-01-01', au: '2023-01-31')

    assert_in_delta 4.0, ligne_agent(users(:martin_technique_paris))[:temps]
    assert_in_delta 4.0, ligne_agent(users(:bond))[:temps]
  end

  test 'le tableau de bord d’un adhérent porte ses conventions de l’année (critique)' do
    sign_in users(:weil)

    travel_to Time.zone.local(2026, 10, 26, 12) do
      get dashboard_url
    end

    assert_equal ['Weil Ariel'], assigns(:conventions).map { |convention| convention[:adherent] }
  end

  test 'le tableau de bord d’un adhérent ne porte pas les conventions des autres adhérents (critique)' do
    sign_in users(:berthout)

    travel_to Time.zone.local(2026, 10, 26, 12) do
      get dashboard_url
    end

    assert_empty assigns(:conventions)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le tableau de bord d’un manager ne porte aucune convention' do
    sign_in users(:hidalgo)

    get dashboard_url

    assert_nil assigns(:conventions)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le matériel est rattaché à l'organisation : ses réservations ne traversent pas le cloisonnement.
  test 'les réservations par jour d’un manager comptent les réservations de matériel de son organisation (critique)' do
    travel_to Time.zone.local(2023, 6, 15, 12)
    reserve(tools(:tondeuse), Date.new(2023, 1, 2), users(:bond))
    reserve(tools(:rateau), Date.new(2023, 1, 2), users(:bond))
    reserve(tools(:tondeuse), Date.new(2023, 1, 3), users(:bond))
    reserve(tools(:outil_marseille), Date.new(2023, 1, 2), users(:agent_marseille))
    sign_in users(:hidalgo)

    get dashboard_url

    assert_equal({ '2023-01-02' => [2], '2023-01-03' => [1] }, assigns(:donnees_graphes)[:reservations])
  end

  test 'les réservations d’un jour listent les outils réservés de l’organisation, par jour puis par nom d’outil (critique)' do
    reserve(tools(:tondeuse), Date.new(2023, 1, 2), users(:bond))
    reserve(tools(:rateau), Date.new(2023, 1, 2), users(:martin_technique_paris))
    reserve(tools(:tondeuse), Date.new(2023, 1, 3), users(:bond))
    reserve(tools(:outil_marseille), Date.new(2023, 1, 2), users(:agent_marseille))
    sign_in users(:hidalgo)

    get dashboard_reservations_du_jour_url(du: '2023-01-02', au: '2023-01-02')

    assert_response :success
    assert_equal [[tools(:rateau).name, users(:martin_technique_paris)], [tools(:tondeuse).name, users(:bond)]],
                 assigns(:mouvements).map { |mouvement| [mouvement.tool.name, mouvement.user] }
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'les réservations du jour sans date demandée sont vides' do
    sign_in users(:hidalgo)

    get dashboard_reservations_du_jour_url

    assert_response :success
    assert_empty assigns(:mouvements)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le temps de la tuile Interventions est borné aux services, et pour un adhérent à ses interventions.
  test 'le temps d’un mois d’un manager est le temps réel de ses services, plus la durée prévue par agent des interventions nouvelles (critique)' do
    cree_intervention_avec_temps(8, adherent: users(:weil), service: services(:technique), debut: Time.zone.local(2023, 1, 15, 9))
    cree_intervention_prevue(Time.zone.local(2023, 2, 10, 9))
    a_deux = cree_intervention_prevue(Time.zone.local(2023, 2, 11, 9))
    AgentIntervention.create!(agent: users(:bond), intervention: a_deux)
    AgentIntervention.create!(agent: users(:martin_technique_paris), intervention: a_deux)
    Intervention.create!(adherent: users(:george_lucas), service: services(:comptabilite), description: 'Hors périmètre',
                         début_prévue: Time.zone.local(2023, 2, 12, 9), fin_prévue: Time.zone.local(2023, 2, 12, 17), workflow_state: Intervention::NOUVEAU)
    refresh_dashboard_views!
    sign_in users(:hidalgo)

    get dashboard_url(du: '2023-01-01', au: '2023-02-28')

    assert_in_delta 8.0, assigns(:donnees_graphes)[:temps]['Technique']['2023-01']
    assert_in_delta 6.0, assigns(:donnees_graphes)[:prevus]['Technique']['2023-02']
    assert_in_delta 0.0, assigns(:donnees_graphes)[:prevus]['Technique']['2023-01']
    assert_nil assigns(:donnees_graphes)[:prevus]['Comptabilité']
  end

  test 'le temps prévu d’un adhérent ne compte que ses interventions nouvelles (critique)' do
    cree_intervention_prevue(Time.zone.local(2023, 2, 10, 9))
    Intervention.create!(adherent: users(:berthout), service: services(:technique), description: 'Prévue pour un autre',
                         début_prévue: Time.zone.local(2023, 2, 11, 9), fin_prévue: Time.zone.local(2023, 2, 11, 17), workflow_state: Intervention::NOUVEAU)
    sign_in users(:weil)

    get dashboard_url(du: '2023-02-01', au: '2023-02-28')

    assert_in_delta 2.0, assigns(:donnees_graphes)[:prevus]['Technique']['2023-02']
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le tableau de bord d’un adhérent ne porte pas les réservations de matériel' do
    sign_in users(:weil)

    get dashboard_url

    assert_nil assigns(:donnees_graphes)[:reservations]
  end

  private

  def cree_intervention_avec_temps(temps, adherent:, service:, debut:, agent: nil)
    intervention = Intervention.create!(
      adherent: adherent,
      service: service,
      description: "Intervention de #{temps} h",
      début: debut,
      workflow_state: Intervention::VALIDE
    )
    intervention.update_columns(temps_total: temps)
    AgentIntervention.create!(agent: agent, intervention: intervention) if agent
    intervention
  end

  def cree_intervention_prevue(debut_prevu)
    Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Intervention planifiée',
                         début_prévue: debut_prevu, fin_prévue: debut_prevu + 2.hours, workflow_state: Intervention::NOUVEAU)
  end

  def reserve(outil, date, agent)
    Mouvement.create!(tool: outil, user: agent, état: :réservé, date: date)
  end

  def mois(n)
    n.months.ago.beginning_of_month.change(hour: 9) + 14.days
  end

  def cree_donnees_adherent_informatique
    cree_intervention_avec_temps(6, adherent: users(:adhérent_sans_intervention),
                                    service: services(:informatique), debut: mois(2))
    refresh_dashboard_views!
  end

  # La ligne d'un agent dans l'activité des agents, nil s'il n'y figure pas.
  def ligne_agent(agent)
    assigns(:activite_agents)[:lignes].find { |ligne| ligne[:agent] == agent }
  end
end
