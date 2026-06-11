# frozen_string_literal: true

class CreateNewsletters < ActiveRecord::Migration[8.0]
  def change
    create_table :newsletters do |t|
      t.string :email
      t.string :slug

      t.timestamps
    end
  end
end
