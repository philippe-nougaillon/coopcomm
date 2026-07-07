# frozen_string_literal: true

class AddMeteoToIntervention < ActiveRecord::Migration[8.0]
  def change
    add_column :interventions, :meteo, :string
  end
end
