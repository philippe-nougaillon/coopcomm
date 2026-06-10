# frozen_string_literal: true

class AddMemoToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :memo, :string
  end
end
