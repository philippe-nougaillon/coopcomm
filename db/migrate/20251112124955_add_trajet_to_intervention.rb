class AddTrajetToIntervention < ActiveRecord::Migration[8.0]
  def change
    add_column :interventions, :trajet, :string
  end
end
