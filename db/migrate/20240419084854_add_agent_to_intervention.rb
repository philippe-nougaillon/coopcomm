# frozen_string_literal: true

class AddAgentToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :agent_id, :integer
    add_index :interventions, :agent_id
    add_column :interventions, :agent_binome_id, :integer
    add_index :interventions, :agent_binome_id
  end
end
