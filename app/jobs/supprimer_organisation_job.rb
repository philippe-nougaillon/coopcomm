# frozen_string_literal: true

class SupprimerOrganisationJob < ApplicationJob
  queue_as :default

  def perform(organisation_id)
    Organisation.find_by(id: organisation_id)&.destroy!
  end
end
