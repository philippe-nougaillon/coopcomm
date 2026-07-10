# frozen_string_literal: true

require 'test_helper'

class OnInterventionUpdatedTest < ActionDispatch::IntegrationTest
  test "NotifAgentsAvisChangedJob mis en file d'attente quand un adhérent modifie le avis d'une intervention" do
    sign_in users(:weil)
    intervention = interventions(:tonte_locaux)

    assert_enqueued_with(job: NotifAgentsAvisChangedJob) do
      patch intervention_path(intervention), params: {
        intervention: { avis: 'Passer la tondeuse sur les plantations ' }
      }
    end
  end
end
