class AddTelephoneToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :téléphone, :string
  end
end
