# frozen_string_literal: true

require 'application_system_test_case'

class AdherentFlowOnDashboardsTest < ApplicationSystemTestCase
  setup do
    @adherent = users(:weil)

    login(@adherent)
    fermer_notification
  end

  test "En tant qu'adhérent, je veux voir mes quatre tuiles dessinées sur mon tableau de bord" do
    travel_to Time.zone.local(2026, 10, 26, 12)
    intervention_dans(services(:technique), users(:martin_technique_paris), debut: Time.zone.local(2026, 2, 10, 9))
    Facture.create!(adherent: @adherent, service: services(:technique), intitulé: 'Facture de tonte',
                    workflow_state: Facture::VALIDE, total_ht: 120, created_at: Time.zone.local(2026, 3, 1, 9))
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableau de bord'

    assert_current_path dashboard_path
    assert_selector "section[data-carte='activiteAgents'] [data-etincelle='#{users(:martin_technique_paris).id}'] svg"
    assert_selector "[data-carte='etatsParMois'] [data-graphe] svg"
    assert_selector '[data-conventions] [data-groupes] [data-libelles]', text: 'Informatique'
    assert_selector "[data-carte='crm'] [data-graphe] svg"
    assert_equal [0, 0, 120, 0, 0, 0, 0, 0, 0, 0, 0, 0], page.evaluate_script("ApexCharts.getChartByID('crm').w.globals.series[2]")
  end

  test "En tant qu'adhérent, je veux limiter mon tableau de bord à un seul de mes services" do
    travel_to Time.zone.local(2026, 10, 26, 12)
    intervention_dans(services(:technique), users(:martin_technique_paris), debut: Time.zone.local(2026, 2, 10, 9))
    intervention_dans(services(:informatique), users(:agent_whatsapp), debut: Time.zone.local(2026, 2, 11, 9))
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableau de bord'
    select_option('#service', 'Technique')

    assert_current_path(/service%5B%5D=#{services(:technique).id}/)
    within "section[data-carte='activiteAgents']" do
      assert_text 'Martin Michel', normalize_ws: true
      assert_no_text 'Poireau Hercule', normalize_ws: true
    end
  end

  test "En tant qu'adhérent, je veux limiter mon tableau de bord à une période" do
    intervention_dans(services(:technique), users(:martin_technique_paris), debut: Time.zone.local(2023, 1, 15, 9))
    intervention_dans(services(:technique), users(:bond), debut: Time.zone.local(2023, 3, 15, 9))
    refresh_dashboard_views!

    cliquer_lien_navbar 'Tableau de bord'
    fill_in 'du', with: Date.new(2023, 1, 1)
    assert_current_path(/du=2023-01-01/)
    fill_in 'au', with: Date.new(2023, 2, 28)

    assert_current_path(/du=2023-01-01&au=2023-02-28/)
    within "section[data-carte='activiteAgents']" do
      assert_text 'Martin Michel', normalize_ws: true
      assert_no_text 'Bond James', normalize_ws: true
    end
  end

  test "En tant qu'adhérent, je veux lire mon tableau de bord sans déborder de l'écran d'un téléphone" do
    cliquer_lien_navbar 'Tableau de bord'

    assert_current_path dashboard_path
    assert_selector "[data-carte='etatsParMois'] [data-graphe] svg"
    assert_equal page.evaluate_script('document.documentElement.clientWidth'),
                 page.evaluate_script('document.documentElement.scrollWidth'),
                 'le tableau de bord déborde horizontalement de l’écran'
  end

  private

  def intervention_dans(service, agent, debut:)
    intervention = Intervention.create!(
      adherent: @adherent, service: service, workflow_state: Intervention::VALIDE,
      description: "Intervention #{service.nom}", début: debut
    )
    intervention.update_columns(temps_total: 4)
    AgentIntervention.create!(agent: agent, intervention: intervention)
    intervention
  end
end
