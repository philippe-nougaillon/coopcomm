# frozen_string_literal: true

class AddAnalyseToConventions < ActiveRecord::Migration[8.1]
  def change
    add_column :conventions, :workflow_state, :string, null: false, default: 'validé'
    add_reference :conventions, :deposant, foreign_key: { to_table: :users }
    add_column :conventions, :analyse, :jsonb
    change_column_null :conventions, :user_id, true
    change_column_null :conventions, :service_id, true
    remove_index :conventions, %i[user_id service_id date_début date_fin_prévue], unique: true,
                 name: 'index_conventions_on_user_id_service_id_and_dates'
    add_index :conventions, %i[user_id service_id date_début date_fin_prévue], unique: true, where: "workflow_state = 'validé'",
              name: 'index_conventions_on_user_id_service_id_and_dates'
    add_check_constraint :conventions, "workflow_state <> 'validé' OR (user_id IS NOT NULL AND service_id IS NOT NULL)",
                         name: 'convention_validee_complete'
  end
end
