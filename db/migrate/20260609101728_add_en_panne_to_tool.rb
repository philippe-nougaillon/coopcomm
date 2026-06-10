class AddEnPanneToTool < ActiveRecord::Migration[8.0]
  def change
    add_column :tools, :en_panne, :boolean
  end
end
