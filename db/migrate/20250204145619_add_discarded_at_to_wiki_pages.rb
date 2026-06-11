# frozen_string_literal: true

class AddDiscardedAtToWikiPages < ActiveRecord::Migration[7.1]
  def change
    add_column :wiki_pages, :discarded_at, :datetime
    add_index :wiki_pages, :discarded_at
  end
end
