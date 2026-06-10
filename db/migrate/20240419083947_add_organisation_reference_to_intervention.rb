# frozen_string_literal: true

class AddOrganisationReferenceToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_reference :interventions, :organisation, null: false, foreign_key: true
  end
end
