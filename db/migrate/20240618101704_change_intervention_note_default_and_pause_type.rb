# frozen_string_literal: true

class ChangeInterventionNoteDefaultAndPauseType < ActiveRecord::Migration[7.1]
  def change
    change_column :interventions, :note, :integer, default: 0
    change_column :interventions, :temps_de_pause, :decimal, default: 0.0
  end
end
