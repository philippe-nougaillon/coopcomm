# frozen_string_literal: true

class CreateAgentInterventions < ActiveRecord::Migration[7.1]
  def change
    create_table :agent_interventions do |t|
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.references :intervention, null: false, foreign_key: true

      t.timestamps
    end

    add_index :agent_interventions, %i[agent_id intervention_id], unique: true
  end
end
