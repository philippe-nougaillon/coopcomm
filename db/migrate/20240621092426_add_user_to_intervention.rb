# frozen_string_literal: true

class AddUserToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_reference :interventions, :user, null: false, foreign_key: true
  end
end
