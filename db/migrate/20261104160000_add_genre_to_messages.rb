# frozen_string_literal: true

class AddGenreToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :genre, :integer, default: 0, null: false
  end
end
