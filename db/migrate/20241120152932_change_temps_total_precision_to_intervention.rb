# frozen_string_literal: true

class ChangeTempsTotalPrecisionToIntervention < ActiveRecord::Migration[7.1]
  def change
    change_column :interventions, :temps_total, :decimal, precision: 8, scale: 2, default: '0.0'
  end
end
