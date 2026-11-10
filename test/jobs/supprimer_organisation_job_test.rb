# frozen_string_literal: true

require 'test_helper'

class SupprimerOrganisationJobTest < ActiveJob::TestCase
  setup do
    @organisation = organisations(:mairie_paris)
  end

  test 'le job supprime l’organisation et ses services (critique)' do
    ids_services = @organisation.services.ids

    SupprimerOrganisationJob.perform_now(@organisation.id)

    assert_nil Organisation.find_by(id: @organisation.id)
    assert_empty Service.where(id: ids_services)
  end

  test 'le job ignore une organisation déjà supprimée' do
    assert_no_difference('Organisation.count') do
      SupprimerOrganisationJob.perform_now(0)
    end
  end
end
