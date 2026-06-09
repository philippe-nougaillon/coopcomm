class AlignCotationTotalHtPrecision < ActiveRecord::Migration[8.0]
  # cotations.total_ht doit pouvoir contenir la somme des cotation_lignes.total_ht
  # (colonne générée en precision: 10), sinon un devis élevé déclenche un
  # "numeric field overflow" lors du recalcul. On aligne les précisions.
  def up
    change_column :cotations, :total_ht, :decimal, precision: 10, scale: 2
  end

  def down
    change_column :cotations, :total_ht, :decimal, precision: 8, scale: 2
  end
end
