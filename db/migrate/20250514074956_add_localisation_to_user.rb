class AddLocalisationToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :localisation, :string
  end
end
