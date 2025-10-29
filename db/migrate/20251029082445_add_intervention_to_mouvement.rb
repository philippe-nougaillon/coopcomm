class AddInterventionToMouvement < ActiveRecord::Migration[8.0]
  def change
    add_reference :mouvements, :intervention, foreign_key: true
  end
end
