# frozen_string_literal: true

class AddAvisToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :avis, :string
  end
end
