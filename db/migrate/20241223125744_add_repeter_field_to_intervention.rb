class AddRepeterFieldToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :repeter, :boolean
  end
end
