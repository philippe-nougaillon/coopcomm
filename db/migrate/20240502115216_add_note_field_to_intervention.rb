# frozen_string_literal: true

class AddNoteFieldToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :note, :integer, default: 5
  end
end
