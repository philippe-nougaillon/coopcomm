class ChangeNotificationsLastSeenAtByMessagesLastSeenAtToMessages < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :notifications_last_seen_at, :messages_last_seen_at
  end
end
