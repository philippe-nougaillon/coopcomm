# frozen_string_literal: true

# Modèle en LECTURE SEULE mappé sur la vue matérialisée `dashboard_agent_stats`.
# Temps total imputé à chaque agent au grain (organisation, agent), répartition
# du temps d'une intervention entre ses agents incluse (cf. db/views/*.sql).
# Rafraîchie par DashboardRefreshable.
class DashboardAgentStat < ApplicationRecord
  belongs_to :organisation
  belongs_to :agent, class_name: 'User'

  scope :for_organisation, ->(org) { where(organisation_id: org) }
  scope :for_agents, ->(agents) { where(agent_id: agents) }

  def readonly?
    true
  end
end
