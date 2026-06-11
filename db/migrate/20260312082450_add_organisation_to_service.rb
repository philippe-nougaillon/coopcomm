# frozen_string_literal: true

class AddOrganisationToService < ActiveRecord::Migration[8.0]
  def change
    add_reference :services, :organisation, null: true, foreign_key: true

    # Ajout de l'organisation associé pour chaque service déjà existant
    Service.all.each do |service|
      service.organisation_id = service.users.first.organisation_id
      service.save
    end

    change_column_null :services, :organisation_id, false
  end
end
