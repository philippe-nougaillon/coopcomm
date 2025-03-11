class RemoveToolFromIntervention < ActiveRecord::Migration[7.1]
  def change
    remove_column :interventions, :tool_id, :integer
  end
end
