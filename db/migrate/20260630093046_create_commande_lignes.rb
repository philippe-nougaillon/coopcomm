class CreateCommandeLignes < ActiveRecord::Migration[8.0]
  def change
    create_table :commande_lignes do |t|
      t.references :commande,   null: false, foreign_key: true
      t.references :prestation, null: false, foreign_key: true
      t.string  :intitulé
      t.integer :qté
      t.decimal :prix_ht, precision: 8, scale: 2
      # Total de la ligne calculé en base (prix unitaire × quantité)
      t.virtual :total_ht, type: :decimal, precision: 10, scale: 2, as: 'prix_ht * qté', stored: true

      t.timestamps
    end
  end
end
