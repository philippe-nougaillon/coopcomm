class AddUserReferenceToWikiPage < ActiveRecord::Migration[7.1]
  def up
    add_reference :wiki_pages, :user, null: true, foreign_key: true
    execute "UPDATE wiki_pages SET user_id = 6 WHERE user_id IS NULL" # Pour les données existantes
    change_column_null :wiki_pages, :user_id, false
  end

  def down
    remove_reference :wiki_pages, :user
  end
end