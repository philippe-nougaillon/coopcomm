# frozen_string_literal: true

class RemoveDefaultTempsDePausefromIntervention < ActiveRecord::Migration[8.0]
  def change
    change_column_default :interventions, :temps_de_pause, nil
  end
end
