# frozen_string_literal: true

class AddChannelFieldToMailLog < ActiveRecord::Migration[7.1]
  def change
    add_column :mail_logs, :channel, :integer
    MailLog.update_all(channel: 0)
  end
end
