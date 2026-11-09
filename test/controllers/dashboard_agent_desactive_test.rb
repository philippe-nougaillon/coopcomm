# frozen_string_literal: true

require 'test_helper'

# Un agent désactivé garde son temps au dashboard, mais pas son nom : sa part est
# cumulée sous « Utilisateur désactivé ».
class DashboardAgentDesactiveTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.current.change(hour: 12)
    @desactive = users_with_discarded(:agent_discarded_paris)
    refresh_dashboard_views!
    sign_in users(:hidalgo)
  end

  test "un agent désactivé figure dans l'activité des agents sous « Utilisateur désactivé », sans son nom" do
    get dashboard_url
    libellés = assigns(:activite_agents)[:lignes].map { |ligne| ligne[:libellé] }

    assert_includes libellés, DashboardController::LIBELLE_AGENT_DESACTIVE
    assert_not_includes libellés, @desactive.nom_prénom
  end

  private

  def users_with_discarded(nom)
    User.with_discarded.find(ActiveRecord::FixtureSet.identify(nom))
  end
end
