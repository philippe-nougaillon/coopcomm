class RemoveOldColumnsFromIntervention < ActiveRecord::Migration[7.1]
  def change
    remove_column :interventions, :agent_id, :integer
    remove_column :interventions, :agent_binome_id, :integer
  end
end
