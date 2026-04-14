class AddOrganisationReferenceAndSlugToWarehouse < ActiveRecord::Migration[8.0]
  def change
    add_reference :warehouses, :organisation, null: false, foreign_key: true
    add_column :warehouses, :slug, :string
  end
end
