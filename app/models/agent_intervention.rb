# frozen_string_literal: true

class AgentIntervention < ApplicationRecord
  audited associated_with: :intervention

  belongs_to :agent, class_name: 'User'
  belongs_to :intervention

  after_commit :actualiser_dashboard

  private

  def actualiser_dashboard
    ActualiserDashboard.call
  end
end
