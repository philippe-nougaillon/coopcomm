class CreatePrestations < ActiveRecord::Migration[8.0]
  def change
    create_table :prestations do |t|
      t.references :organisation, null: false, foreign_key: true
      t.string  :code
      t.string  :libellé
      t.string  :catégorie
      t.string  :sous_catégorie
      t.string  :description
      t.string  :unité
      t.decimal :tarif, precision: 8, scale: 2
      t.string  :compétence
      t.string  :délai

      t.timestamps
    end

    # Un code de prestation est unique au sein d'une organisation
    add_index :prestations, [:organisation_id, :code], unique: true
  end
end
