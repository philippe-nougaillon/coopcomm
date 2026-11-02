# frozen_string_literal: true

require 'application_system_test_case'

class ManagerFlowOnDashboardsTest < ApplicationSystemTestCase
  setup do
    login(users(:hidalgo))
    fermer_notification
  end

  test "En tant que manager, je veux lire les graphes mensuels de mon tableau de bord sur un téléphone" do
    intervention_de(agent_technique(0), temps: 3)
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableaux de bord'

    assert_current_path dashboard_path
    %w[etatsParMois crm].each do |carte|
      assert_selector "[data-carte='#{carte}'] [data-graphe] svg"
    end
    assert_equal page.evaluate_script('document.documentElement.clientWidth'),
                 page.evaluate_script('document.documentElement.scrollWidth'),
                 'le tableau de bord déborde horizontalement de l’écran'
    graphe = "document.querySelector('[data-carte=\"etatsParMois\"] [data-graphe]')"
    assert_operator page.evaluate_script("#{graphe}.scrollWidth"), :>, page.evaluate_script("#{graphe}.clientWidth"),
                    'le graphe des interventions ne défile pas en largeur téléphone'
  end

  test "En tant que manager, je veux restreindre l'activité des agents à un seul service" do
    travel_to Time.zone.local(2022, 3, 15, 12)
    intervention_du_10_fevrier_2022(users(:martin_technique_paris), service: services(:technique), adherent: users(:weil))
    intervention_du_10_fevrier_2022(users(:agent_whatsapp), service: services(:service_paris), adherent: users(:patrick_adherent_paris))
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableaux de bord'

    within 'section[data-carte="activiteAgents"]' do
      assert_text 'Poireau Hercule', normalize_ws: true
    end

    select_option('#filtre-services-activiteAgents', 'Technique')

    assert_current_path(/agents_service=Technique/)
    within 'section[data-carte="activiteAgents"]' do
      assert_text 'Martin Michel', normalize_ws: true
      assert_no_text 'Poireau Hercule', normalize_ws: true
    end
  end

  test "En tant que manager, je veux basculer les courbes de l'activité des agents du temps aux interventions" do
    travel_to Time.zone.local(2022, 3, 15, 12)
    intervention_du_10_fevrier_2022(users(:martin_technique_paris), service: services(:technique), adherent: users(:weil))
    refresh_dashboard_views!
    courbe = "JSON.parse(document.querySelector(\"[data-etincelle='#{users(:martin_technique_paris).id}']\").dataset.valeurs)"

    cliquer_lien_navbar 'Tableaux de bord'

    assert_selector "section[data-carte='activiteAgents'] [data-etincelle='#{users(:martin_technique_paris).id}'] svg"
    assert_equal [0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], page.evaluate_script(courbe)

    cliquer_element(find('section[data-carte="activiteAgents"] [data-mesure] label', text: 'Interventions'))

    assert_equal [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], page.evaluate_script(courbe)
  end

  test "En tant que manager, je veux lire mes quatre tuiles sans faire défiler la page sur un ordinateur" do
    travel_to Time.zone.local(2022, 3, 15, 12)
    deux_tontes_du_10_fevrier_2022
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableaux de bord'
    assert_current_path dashboard_path
    page.current_window.resize_to(*self.class.taille_pc)
    visit current_url

    %w[activiteAgents etatsParMois reservations crm].each { |tuile| assert_selector "[data-carte='#{tuile}']", visible: true }
    assert_selector "[data-carte='crm'] [data-graphe] svg"
    assert_includes page.evaluate_script("ApexCharts.getChartByID('etatsParMois').w.globals.seriesNames"), 'Temps'
    assert_operator page.evaluate_script('document.documentElement.scrollHeight'), :<=,
                    page.evaluate_script('document.documentElement.clientHeight'),
                    'le tableau de bord déborde verticalement de l’écran'
  ensure
    page.current_window.resize_to(*self.class.taille_tel)
  end

  test "En tant que manager, je veux ouvrir la liste du matériel réservé un jour depuis le calendrier des outils" do
    travel_to Time.zone.local(2022, 3, 15, 12)
    Mouvement.create!(tool: tools(:tondeuse), user: users(:bond), état: :réservé, date: Date.new(2022, 2, 10))
    Mouvement.create!(tool: tools(:rateau), user: users(:bond), état: :réservé, date: Date.new(2022, 2, 12))
    Mouvement.create!(tool: tools(:rateau), user: users(:bond), état: :réservé, date: Date.new(2022, 2, 13))

    cliquer_lien_navbar 'Tableaux de bord'
    within '[data-carte="reservations"]' do
      assert_text '3 réservations en 2022'
      assert_selector '.apexcharts-yaxis-label', text: 'sam.'
      assert_selector '.apexcharts-yaxis-label', text: 'dim.'
    end
    cellule = find('[data-carte="reservations"] rect[i="3"][val="1"]')
    survoler(cellule)
    cellule.click

    within 'dialog[open]' do
      assert_text 'Matériel réservé le jeudi 10 février 2022'
      assert_text tools(:tondeuse).name
      assert_text 'Bond James'
    end
  end

  test "En tant que manager, je veux lire le calendrier des outils en grandes cases ouvert sur aujourd'hui, ou en petites cases qui tiennent dans la tuile" do
    travel_to Time.zone.local(2022, 8, 16, 12)

    cliquer_lien_navbar 'Tableaux de bord'
    assert_current_path dashboard_path
    page.current_window.resize_to(*self.class.taille_pc)
    visit current_url
    grandes = mesures_du_calendrier('reservations')

    within('[data-carte="reservations"]') { cliquer_lien 'Petites cases' }
    assert_current_path(/outils=petites/)

    petites = mesures_du_calendrier('reservations')
    assert_operator grandes['pas'], :>, petites['pas'], 'les grandes cases ne sont pas plus grandes que les petites'
    assert_in_delta grandes['hauteurCadre'], grandes['hauteurCalendrier'], 2, 'le calendrier en grandes cases ne prend pas toute la hauteur de sa tuile'
    assert_in_delta grandes['largeurCase'], grandes['hauteurCase'], 1, 'les grandes cases ne sont pas carrées'
    assert_operator grandes['largeurTotale'], :>, grandes['largeurVisible'], 'le calendrier en grandes cases ne déborde pas de sa tuile'
    assert_in_delta [[grandes['centre'] - grandes['largeurVisible'] / 2.0, 0].max, grandes['largeurTotale'] - grandes['largeurVisible']].min,
                    grandes['defilement'], 2, 'la case d’aujourd’hui n’est pas au milieu du calendrier'
    assert_operator petites['largeurTotale'], :<=, petites['largeurVisible'], 'le calendrier en petites cases déborde de sa tuile'
  ensure
    page.current_window.resize_to(*self.class.taille_tel)
  end

  test "En tant que manager, je veux trier l'activité de mes agents sans recharger la page" do
    travel_to Time.zone.local(2022, 3, 15, 12)
    intervention_du_10_fevrier_2022(users(:martin_technique_paris), service: services(:technique), adherent: users(:weil))
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableaux de bord'
    page.execute_script('window.temoin = 42')
    premier = find('turbo-frame#activite-agents tbody tr[data-agent]', match: :first).text(normalize_ws: true)
    assert_includes premier, 'Martin Michel'

    cliquer_lien 'Agent'

    assert_current_path(/column=agents\.nom&direction=asc/)
    assert_selector "turbo-frame#activite-agents [data-etincelle='#{users(:martin_technique_paris).id}'] svg"
    assert_not_equal premier, find('turbo-frame#activite-agents tbody tr[data-agent]', match: :first).text(normalize_ws: true)
    assert_equal 42, page.evaluate_script('window.temoin')
  end

  private

  def intervention_du_10_fevrier_2022(agent, service:, adherent:)
    intervention = Intervention.create!(adherent: adherent, service: service, workflow_state: Intervention::VALIDE,
                                        description: "Intervention de #{agent.nom}", début: Time.zone.local(2022, 2, 10, 9))
    intervention.update_columns(temps_total: 3)
    AgentIntervention.create!(agent: agent, intervention: intervention)
  end

  def deux_tontes_du_10_fevrier_2022
    2.times do |rang|
      Intervention.create!(adherent: users(:weil), service: services(:technique), workflow_state: Intervention::VALIDE,
                           description: "Tonte du stade #{rang + 1}", début: Time.zone.local(2022, 2, 10, 9 + rang))
                  .update_columns(temps_total: 3)
    end
  end

  # Centrer avant de survoler : aligné en bas, l'élément passe sous le dock fixe et le survol ne l'atteint pas.
  def survoler(element)
    scroll_to(element, align: :center)
    element.hover
  end

  def agent_technique(rang)
    User.create!(nom: "Agent #{rang}", prénom: 'Test', email: "agent#{rang}@test.fr", password: 'qtDug$d843sqACz?V',
                 rôle: :agent, services: [services(:technique)])
  end

  def intervention_de(agent, temps:)
    intervention = Intervention.create!(
      adherent: users(:weil), service: services(:technique), workflow_state: Intervention::VALIDE,
      description: "Intervention de #{agent.nom}", début: 1.month.ago.beginning_of_month.change(hour: 9)
    )
    intervention.update_columns(temps_total: temps)
    AgentIntervention.create!(agent: agent, intervention: intervention)
  end

  # Calendrier d'une carte, en pixels : pas et côtés d'une case, hauteurs du calendrier et de son cadre, centre de la
  # case d'aujourd'hui dans le contenu, largeur visible, défilement et largeur totale du cadre.
  def mesures_du_calendrier(carte)
    assert_selector "[data-carte='#{carte}'] .apexcharts-aujourdhui", visible: :all
    page.evaluate_script(<<~JS)
      (() => {
        const cadre = document.querySelector("[data-carte='#{carte}'] [data-graphe]").parentElement
        const cases = cadre.querySelectorAll("rect.apexcharts-heatmap-rect[i='0']")
        const boite = cadre.getBoundingClientRect()
        const aujourdhui = cadre.querySelector('.apexcharts-aujourdhui').getBoundingClientRect()
        return { pas: cases[1].getAttribute('x') - cases[0].getAttribute('x'),
                 largeurCase: Number(cases[0].getAttribute('width')), hauteurCase: Number(cases[0].getAttribute('height')),
                 hauteurCalendrier: cadre.querySelector('svg.apexcharts-svg').getBoundingClientRect().height, hauteurCadre: cadre.clientHeight,
                 centre: aujourdhui.left + aujourdhui.width / 2 - boite.left + cadre.scrollLeft,
                 largeurVisible: cadre.clientWidth, defilement: cadre.scrollLeft, largeurTotale: cadre.scrollWidth }
      })()
    JS
  end
end
