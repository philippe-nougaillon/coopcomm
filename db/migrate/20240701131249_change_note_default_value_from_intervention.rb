# frozen_string_literal: true

class ChangeNoteDefaultValueFromIntervention < ActiveRecord::Migration[7.1]
  def change
    change_column :interventions, :note, :integer, default: 5
  end
end
