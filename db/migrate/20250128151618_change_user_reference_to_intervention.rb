# frozen_string_literal: true

class ChangeUserReferenceToIntervention < ActiveRecord::Migration[7.1]
  def change
    rename_column :interventions, :user_id, :team_id
    change_column_null :interventions, :team_id, true

    remove_foreign_key :interventions, :users
    add_foreign_key :interventions, :users, column: :team_id
  end
end
