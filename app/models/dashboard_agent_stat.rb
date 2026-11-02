# frozen_string_literal: true

# Lecture seule : vue matérialisée rafraîchie après chaque commit d'Intervention ou d'AgentIntervention, au grain
# (organisation, service, agent, mois), temps d'une intervention réparti entre ses agents,
# désactivés compris (le dashboard les regroupe sous « Utilisateur désactivé »).
class DashboardAgentStat < ApplicationRecord
  belongs_to :organisation
  belongs_to :agent, class_name: 'User'

  scope :for_services, ->(services) { where(service_id: services) }
  scope :between_months, ->(start_date, end_date) {
    where(mois: start_date.to_date.beginning_of_month..end_date.to_date.end_of_month)
  }

  def readonly?
    true
  end
end
