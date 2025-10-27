class CreateMouvements < ActiveRecord::Migration[8.0]
  def change
    create_table :mouvements do |t|
      t.references :tool, null: false, foreign_key: true
      t.integer :état
      t.string :slug

      t.timestamps
    end
  end
end
