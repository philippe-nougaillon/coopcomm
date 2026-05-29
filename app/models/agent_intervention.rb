class AgentIntervention < ApplicationRecord
  audited associated_with: :intervention

  belongs_to :agent, class_name: 'User', touch: true
  belongs_to :intervention
end
