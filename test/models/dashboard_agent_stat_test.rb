# frozen_string_literal: true

require 'test_helper'

# La vue dashboard_agent_stats répartit le temps d'une intervention entre TOUS ses
# agents, désactivés compris (v03) : le total est ainsi conservé quand un compte est
# désactivé, et la vue ne dépend plus de users.discarded_at.
class DashboardAgentStatTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test "une statistique d'agent du tableau de bord est en lecture seule" do
    assert DashboardAgentStat.new.readonly?
  end

  test 'le temps par agent du tableau de bord est identique au calcul live' do
    User.with_discarded.where(rôle: :agent).find_each do |agent|
      live = Intervention.joins(:agent_interventions).where(agent_interventions: { agent_id: agent.id }).sum do |i|
        n = AgentIntervention.where(intervention_id: i.id).count
        n.zero? ? 0 : i.temps_total.to_f / n
      end
      vue = DashboardAgentStat.where(agent_id: agent.id).sum(:temps_total)

      assert_in_delta live.to_f, vue.to_f, 0.0001, "agent ##{agent.id} #{agent.nom_prénom}"
    end
  end

  test 'un agent désactivé garde sa part du temps dans le tableau de bord' do
    discarded = User.with_discarded.discarded.agent.first

    assert_not_nil discarded, 'aucun agent supprimé dans les fixtures'

    iv = discarded.interventions.find { |i| i.temps_total.to_f.positive? }

    assert_not_nil iv, 'agent supprimé sans intervention chiffrée dans les fixtures'
    part = iv.temps_total / AgentIntervention.where(intervention_id: iv.id).count

    assert_in_delta part, DashboardAgentStat.where(agent_id: discarded.id).sum(:temps_total), 0.01
  end

  test "le temps d'une intervention est intégralement réparti entre ses agents dans le tableau de bord" do
    affectées = Intervention.where(id: AgentIntervention.select(:intervention_id))

    assert_in_delta affectées.sum(:temps_total), DashboardAgentStat.sum(:temps_total), 0.01
  end
end
