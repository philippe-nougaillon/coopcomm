class AddSlugToCotationsAndPrestations < ActiveRecord::Migration[8.0]
  def change
    add_column :cotations, :slug, :string
    add_index :cotations, :slug, unique: true

    add_column :prestations, :slug, :string
    add_index :prestations, :slug, unique: true
  end
end
