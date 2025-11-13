class AddCo2ToIntervention < ActiveRecord::Migration[8.0]
  def change
    add_column :interventions, :co2, :decimal, default: 0.0
  end
end
