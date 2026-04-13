class AddLocalisationToIntervention < ActiveRecord::Migration[8.0]
  def change
    add_column :interventions, :localisation, :string
  end
end
