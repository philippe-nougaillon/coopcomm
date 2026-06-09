class CreateCotations < ActiveRecord::Migration[8.0]
  def change
    create_table :cotations do |t|
      t.references :adherent, null: false, foreign_key: { to_table: :users }
      t.references :service,  null: false, foreign_key: true
      t.string   :ref
      t.string   :intitulé
      t.text     :mémo
      t.integer  :statut, default: 0
      t.date     :date_livraison_souhaitée
      t.decimal  :total_ht, precision: 8, scale: 2
      t.datetime :discarded_at

      t.timestamps
    end

    add_index :cotations, :discarded_at
  end
end
