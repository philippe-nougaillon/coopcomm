class UpdateHeuresConsommeesValueFromConvention < ActiveRecord::Migration[8.0]
  def change
    Convention.all.each do |convention|
      convention.heures_consommees = convention.interventions.sum(:temps_total)
      convention.save
    end
  end
end
