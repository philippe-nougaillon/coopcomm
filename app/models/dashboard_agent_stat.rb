# frozen_string_literal: true

# Lecture seule : vue matérialisée rafraîchie par DashboardRefreshable, au grain
# (organisation, agent), temps d'une intervention réparti entre ses agents.
class DashboardAgentStat < ApplicationRecord
  belongs_to :organisation
  belongs_to :agent, class_name: 'User'

  scope :for_organisation, ->(org) { where(organisation_id: org) }
  scope :for_agents, ->(agents) { where(agent_id: agents) }

  def readonly?
    true
  end
end
