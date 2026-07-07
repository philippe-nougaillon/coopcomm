class AddDefaultValueInHeuresConventionneesFromConvetions < ActiveRecord::Migration[8.0]
  def change
    change_column_default :conventions, :heures_conventionnees, from: nil, to: 0

    Convention.update_all(heures_conventionnees: 0)
  end
end
