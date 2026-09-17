class CreateAibotLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :aibot_logs do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :request_message, null: false, foreign_key: { to_table: :messages, on_delete: :cascade }
      t.references :response_message, null: false, foreign_key: { to_table: :messages, on_delete: :cascade }
      t.boolean :succes, null: false, default: false
      t.text :log_stream
      t.string :slug, :string

      t.timestamps
    end
  end
end
