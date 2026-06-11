# frozen_string_literal: true

class AddDefaultValueToTempsDePause < ActiveRecord::Migration[7.1]
  def change
    change_column :interventions, :temps_de_pause, :integer, default: 0
  end
end
