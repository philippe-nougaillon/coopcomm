class AddHeuresConventionneesToConventions < ActiveRecord::Migration[8.0]
  def change
    add_column :conventions, :heures_conventionnees, :decimal, precision: 10, scale: 2
  end
end
