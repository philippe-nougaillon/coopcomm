class RemoveServiceIdFromUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :service_id, :bigint
  end
end
