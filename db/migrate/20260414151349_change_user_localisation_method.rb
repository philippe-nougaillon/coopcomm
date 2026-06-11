# frozen_string_literal: true

class ChangeUserLocalisationMethod < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :localisation, :string
    add_column :users, :address, :string
    add_column :users, :latitude, :decimal, precision: 10, scale: 6
    add_column :users, :longitude, :decimal, precision: 10, scale: 6
  end
end
