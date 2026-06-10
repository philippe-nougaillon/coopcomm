# frozen_string_literal: true

class AddNomPrenomRoleFieldsToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :nom, :string
    add_column :users, :prénom, :string
    add_column :users, :rôle, :integer, default: 0, null: false
  end
end
