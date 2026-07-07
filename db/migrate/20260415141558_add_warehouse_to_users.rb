# frozen_string_literal: true

class AddWarehouseToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :warehouse, null: true, foreign_key: true
  end
end
