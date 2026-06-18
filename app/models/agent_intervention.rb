# frozen_string_literal: true

class AgentIntervention < ApplicationRecord
  include DashboardRefreshable

  audited associated_with: :intervention

  belongs_to :agent, class_name: 'User'
  belongs_to :intervention

  # L'affectation/désaffectation d'un agent change la répartition du temps
  # par agent (vue dashboard_agent_stats).
  after_commit :enqueue_dashboard_refresh, on: %i[create destroy]
end
