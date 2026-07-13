class AddSignatureFieldsToCotation < ActiveRecord::Migration[8.0]
  def change
    add_column :cotations, :signature, :string
    add_column :cotations, :signee_le, :datetime
    add_column :cotations, :ip, :string
  end
end
