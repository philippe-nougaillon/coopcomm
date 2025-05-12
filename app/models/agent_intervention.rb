class AgentIntervention < ApplicationRecord
  belongs_to :agent, class_name: 'User'
  belongs_to :intervention
end
