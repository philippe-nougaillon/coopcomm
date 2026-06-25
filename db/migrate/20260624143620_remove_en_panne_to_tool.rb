class RemoveEnPanneToTool < ActiveRecord::Migration[8.0]
  def change
    remove_column :tools, :en_panne, :boolean, default: false
  end
end
