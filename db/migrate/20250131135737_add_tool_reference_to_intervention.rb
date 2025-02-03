class AddToolReferenceToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_reference :interventions, :tool, foreign_key: true
  end
end
