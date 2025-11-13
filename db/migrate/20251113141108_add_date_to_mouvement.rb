class AddDateToMouvement < ActiveRecord::Migration[8.0]
  def change
    add_column :mouvements, :date, :datetime
  end
end
