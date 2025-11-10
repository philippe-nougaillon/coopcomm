class AddColorToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :color, :string
  end
end
