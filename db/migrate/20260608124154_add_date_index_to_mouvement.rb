class AddDateIndexToMouvement < ActiveRecord::Migration[8.0]
  def change
    add_index :mouvements, :date
  end
end
