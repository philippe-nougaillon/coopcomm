# frozen_string_literal: true

class CreateWikiPages < ActiveRecord::Migration[7.1]
  def change
    create_table :wiki_pages do |t|
      t.string :titre, null: false
      t.boolean :publiée, default: false
      t.integer :poids, default: 0
      t.integer :catégorie
      t.string :slug

      t.timestamps
    end

    add_index :wiki_pages, :slug, unique: true
  end
end
