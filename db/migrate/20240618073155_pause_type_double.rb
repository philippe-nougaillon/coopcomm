# frozen_string_literal: true

class PauseTypeDouble < ActiveRecord::Migration[7.1]
  def change
    change_column :interventions, :temps_de_pause, :float, default: 0
  end
end
