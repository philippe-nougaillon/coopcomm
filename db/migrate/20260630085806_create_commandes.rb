class CreateCommandes < ActiveRecord::Migration[8.0]
  def change
    create_table :commandes do |t|
      t.references :adherent, null: false, foreign_key: { to_table: :users }
      t.references :service,  null: false, foreign_key: true
      t.string   :ref
      t.string   :intitulé
      t.text     :mémo
      t.string   :workflow_state, default: "créé"
      t.date     :date_livraison_souhaitée
      t.decimal  :total_ht, precision: 10, scale: 2
      t.datetime :discarded_at
      t.string   :slug

      t.timestamps
    end

    add_index :commandes, :discarded_at
    add_index :commandes, :slug, unique: true
  end
end
