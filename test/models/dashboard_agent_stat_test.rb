# frozen_string_literal: true

require 'test_helper'

# La vue dashboard_agent_stats doit reproduire le calcul historique NON FILTRÉ de
# DashboardData#temps_par_agent : temps d'une intervention réparti entre ses agents NON…
class DashboardAgentStatTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test 'est en lecture seule' do
    assert DashboardAgentStat.new.readonly?
  end

  test 'temps par agent identique au calcul live, pour chaque agent kept' do
    User.where(rôle: :agent).find_each do |agent|
      live = agent.interventions.sum do |i|
        n = i.agents.size
        n.zero? ? 0 : i.temps_total / n
      end
      vue = DashboardAgentStat.where(agent_id: agent.id).sum(:temps_total)
      assert_in_delta live.to_f, vue.to_f, 0.0001, "agent ##{agent.id} #{agent.nom_prénom}"
    end
  end

  test 'aucune ligne pour un agent supprimé (discarded)' do
    discarded = User.unscoped.where(rôle: :agent).where.not(discarded_at: nil).first
    skip 'aucun agent supprimé dans les fixtures' if discarded.nil?
    assert_equal 0, DashboardAgentStat.where(agent_id: discarded.id).count
  end
end
