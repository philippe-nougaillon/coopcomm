# frozen_string_literal: true

class RenameNotificationToMessage < ActiveRecord::Migration[8.0]
  def change
    rename_table :notifications, :messages
  end
end
