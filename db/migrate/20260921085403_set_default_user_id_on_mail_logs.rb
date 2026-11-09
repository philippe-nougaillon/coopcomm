class SetDefaultUserIdOnMailLogs < ActiveRecord::Migration[8.1]
  def up
    change_column_default :mail_logs, :user_id, from: nil, to: 0
    execute 'UPDATE mail_logs SET user_id = 0 WHERE user_id IS NULL'
  end

  def down
    change_column_default :mail_logs, :user_id, from: 0, to: nil
  end
end
