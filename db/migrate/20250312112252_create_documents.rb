# frozen_string_literal: true

class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.string :category
      t.string :workflow_state
      t.references :tool, null: false, foreign_key: true

      t.timestamps
    end
  end
end
