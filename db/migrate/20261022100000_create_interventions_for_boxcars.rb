# frozen_string_literal: true

class CreateInterventionsForBoxcars < ActiveRecord::Migration[8.0]
  def change
    create_view :interventions_for_boxcars
  end
end
