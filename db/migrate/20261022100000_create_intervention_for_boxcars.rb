# frozen_string_literal: true

class CreateInterventionForBoxcars < ActiveRecord::Migration[8.0]
  def change
    create_view :intervention_for_boxcars
  end
end
