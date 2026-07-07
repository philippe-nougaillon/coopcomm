# frozen_string_literal: true

class AddTempsTotalToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :temps_total, :decimal, precision: 4, scale: 2, default: '0.0'
  end
end
