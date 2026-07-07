# frozen_string_literal: true

class CreateTools < ActiveRecord::Migration[7.1]
  def change
    create_table :tools do |t|
      t.string :name
      t.string :description
      t.references :organisation, null: false, foreign_key: true
      t.string :slug

      t.timestamps
    end
  end
end
