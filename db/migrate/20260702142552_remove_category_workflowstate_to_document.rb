class RemoveCategoryWorkflowstateToDocument < ActiveRecord::Migration[8.0]
  def change
    remove_column :documents, :category, :string
    remove_column :documents, :workflow_state, :string
  end
end
