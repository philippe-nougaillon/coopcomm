# frozen_string_literal: true

require 'test_helper'

class OnInterventionWorkflowChangedTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:martin_technique_paris)
  end

  test "NotifManagersWorkflowChangedJob mis en file d'attente quand un agent termine une intervention avec un manageur dans l'organisation" do
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      get terminer_intervention_path(intervention)
    end
  end

  test "NotifManagersWorkflowChangedJob mis en file d'attente quand un agent valide une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_terminée)

    assert_enqueued_jobs 0 do
      get valider_intervention_path(intervention)
    end
  end

  test "NotifManagersWorkflowChangedJob pas mis en file d'attente quand un agent refuse une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_terminée)

    assert_enqueued_jobs 0 do
      get refuser_intervention_path(intervention)
    end
  end

  test "NotifManagersWorkflowChangedJob mis en file d'attente quand un agent archive une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_validé)

    assert_enqueued_jobs 0 do
      get archiver_intervention_path(intervention)
    end
  end

  # test "NotifManagersWorkflowChangedJob n'est pas mis en file d'attente si un agent modifie le statut avec une organisation sans manager" do
  #   sign_in users(:john_wick)
  #   intervention = interventions(:intervention_sans_manager)
  #
  #   assert_enqueued_jobs 0 do
  #     get terminer_intervention_path(intervention)
  #   end
  # end

  # Permet de tester quand un manager termine une intervention, que ca ne notifie pas les manager, comme lui-même est un utilisateur
  test "NotifManagersWorkflowChangedJob n'est pas mis en file d'attente si un manager modifie le statut" do
    sign_in users(:manager_marseille)
    intervention = interventions(:nettoyage_port)

    assert_enqueued_jobs 0 do
      get terminer_intervention_path(intervention)
    end
  end
end
