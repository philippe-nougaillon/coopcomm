# frozen_string_literal: true

class CreateInterventions < ActiveRecord::Migration[7.1]
  def change
    create_table :interventions do |t|
      t.datetime :début
      t.datetime :fin
      t.integer :temps_de_pause
      t.string :description
      t.string :workflow_state

      t.timestamps
    end
  end
end
