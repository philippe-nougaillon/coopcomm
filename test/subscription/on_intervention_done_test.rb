# frozen_string_literal: true

require 'test_helper'

class OnInterventionDoneTest < ActionDispatch::IntegrationTest
  test "le mail d'intervention terminée à l'adhérent est mis en file lorsqu'un agent termine son intervention" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
      post terminer_intervention_path(intervention)
    end
  end
end
