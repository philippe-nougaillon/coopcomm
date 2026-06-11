# frozen_string_literal: true

require 'test_helper'

class OnInterventionUpdatedTest < ActionDispatch::IntegrationTest
  test "NotifAgentsCommentairesChangedJob mis en file d'attente quand un adhérent modifie le commentaire d'une intervention" do
    sign_in users(:weil)
    intervention = interventions(:tonte_locaux)

    assert_enqueued_with(job: NotifAgentsCommentairesChangedJob) do
      patch intervention_path(intervention), params: {
        intervention: { commentaires: 'Passer la tondeuse sur les plantations ' }
      }
    end
  end
end
