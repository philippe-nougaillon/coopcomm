# frozen_string_literal: true

require 'application_system_test_case'

class AdherentFlowOnDashboardsTest < ApplicationSystemTestCase
  # Les six graphes déclarés par `build_dashboard_for_adherent`, et l'identifiant
  # du canvas que Chart.js doit alimenter pour chacun.
  GRAPHES = {
    'proportion du temps consommé' => 'proportionTempsConsomméChart',
    'états du workflow' => 'workflowChart',
    'quantité d’interventions par service' => 'qtéInterventionsParServiceChart',
    'temps total par service' => 'tempsTotalParServiceChart',
    'temps total par mois' => 'tempsTotalParMoisChart',
    'CO2 total par mois' => 'co2TotalParMois'
  }.freeze

  setup do
    @adherent = users(:weil)

    login(@adherent)
    fermer_notification
  end

  test "En tant qu'adhérent, je veux voir tous les graphes de mon tableau de bord dessinés" do
    # Deux services : sous ce seuil, la vue remplace deux des graphes par une
    # tuile chiffrée — c'est voulu, mais on ne verrait alors pas tous les types.
    intervention_dans(services(:technique))
    intervention_dans(services(:informatique))
    refresh_dashboard_views!
    
    cliquer_lien_navbar 'Tableau de bord'

    assert_current_path dashboard_path

    GRAPHES.each do |intitulé, canvas|
      flunk "Le graphe « #{intitulé} » n'existe pas sur le tableau de bord" unless has_css?("##{canvas}", visible: :all)

      dessiné = page.evaluate_script("Boolean(Chart.getChart('#{canvas}'))")
      flunk "Le graphe « #{intitulé} » n'est pas dessiné : Chart.js n'a rien attaché à ##{canvas}" unless dessiné
    end
  end

  private

  def intervention_dans(service)
    intervention = Intervention.create!(
      adherent: @adherent, service: service, workflow_state: Intervention::VALIDE,
      description: "Intervention #{service.nom}", début: 1.month.ago.beginning_of_month.change(hour: 9)
    )
    intervention.update_columns(temps_total: 4)
    intervention
  end
end
