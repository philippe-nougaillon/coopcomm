class RemoveServiceToUser < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :service, :string
  end
end
