class AddCotationToMailLogs < ActiveRecord::Migration[8.0]
  def change
    add_reference :mail_logs, :cotation, null: true, foreign_key: true
  end
end
