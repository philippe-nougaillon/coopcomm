# frozen_string_literal: true

# Lecture seule : vue matérialisée rafraîchie après chaque commit d'Intervention ou d'AgentIntervention, au grain
# (organisation, agent), temps d'une intervention réparti entre ses agents,
# désactivés compris (le dashboard les regroupe sous « Utilisateur désactivé »).
class DashboardAgentStat < ApplicationRecord
  belongs_to :organisation
  belongs_to :agent, class_name: 'User'

  def readonly?
    true
  end
end
