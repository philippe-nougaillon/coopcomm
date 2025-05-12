class AddEpingleeFieldToWikiPage < ActiveRecord::Migration[7.1]
  def change
    add_column :wiki_pages, :épinglée, :boolean
  end
end
