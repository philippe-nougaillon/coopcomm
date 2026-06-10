# frozen_string_literal: true

class CreateExportLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :export_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organisation, null: false, foreign_key: true
      t.string :export_type

      t.timestamps
    end
  end
end
