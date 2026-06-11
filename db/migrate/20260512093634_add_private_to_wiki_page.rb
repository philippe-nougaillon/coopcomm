# frozen_string_literal: true

class AddPrivateToWikiPage < ActiveRecord::Migration[8.0]
  def change
    add_column :wiki_pages, :private, :boolean, default: true
  end
end
