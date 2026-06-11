# frozen_string_literal: true

class ChangeWarehouseLocalisationMethod < ActiveRecord::Migration[8.0]
  def change
    remove_column :warehouses, :localisation, :string
    add_column :warehouses, :address, :string
    add_column :warehouses, :latitude, :decimal, precision: 10, scale: 6
    add_column :warehouses, :longitude, :decimal, precision: 10, scale: 6
  end
end
