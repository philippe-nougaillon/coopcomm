# frozen_string_literal: true

class AddSlugToDocument < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :slug, :string
  end
end
