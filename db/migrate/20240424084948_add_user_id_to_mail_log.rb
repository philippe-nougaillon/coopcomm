# frozen_string_literal: true

class AddUserIdToMailLog < ActiveRecord::Migration[7.1]
  def change
    add_column :mail_logs, :user_id, :integer
  end
end
