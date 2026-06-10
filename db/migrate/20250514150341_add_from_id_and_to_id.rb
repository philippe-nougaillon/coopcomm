# frozen_string_literal: true

class AddFromIdAndToId < ActiveRecord::Migration[8.0]
  def change
    remove_column :notifications, :user_id, :bigint

    add_column :notifications, :from_id, :bigint
    add_index :notifications, :from_id

    add_column :notifications, :to_id, :bigint
    add_index :notifications, :to_id
  end
end
