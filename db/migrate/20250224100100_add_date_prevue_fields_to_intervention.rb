class AddDatePrevueFieldsToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :début_prévue, :datetime
    add_column :interventions, :fin_prévue, :datetime
  end
end
