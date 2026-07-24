class AddRefToConvention < ActiveRecord::Migration[8.0]
  def change
    add_column :conventions, :ref, :string
  end
end
