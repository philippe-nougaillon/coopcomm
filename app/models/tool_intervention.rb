class ToolIntervention < ApplicationRecord
  audited associated_with: :intervention

  belongs_to :tool
  belongs_to :intervention
end