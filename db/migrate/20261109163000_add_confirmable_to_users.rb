class AddConfirmableToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :confirmation_token
      t.datetime :confirmed_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime :confirmation_sent_at
      t.index :confirmation_token, unique: true
    end
  end
end
