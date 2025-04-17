class AddVersionToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :version, :decimal, precision: 5, scale: 1
  end
end
