class AddDatesToIndexConventionUserService < ActiveRecord::Migration[8.0]
  def change
    remove_index :conventions,
               column: [:user_id, :service_id],
               name: "index_conventions_on_user_id_and_service_id",
               unique: true

    add_index :conventions,
              [:user_id, :service_id, :date_début, :date_fin_prévue],
              name: "index_conventions_on_user_id_service_id_and_dates",
              unique: true
  end
end
