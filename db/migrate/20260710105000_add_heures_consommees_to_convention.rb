class AddHeuresConsommeesToConvention < ActiveRecord::Migration[8.0]
  def change
    add_column :conventions, :heures_consommees, :decimal, precision: 8, scale: 2, default: "0.0"
  end
end
