# frozen_string_literal: true

require 'test_helper'

class OnInterventionWorkflowChangedTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:martin_technique_paris)
  end

  test "le mail de changement de statut aux managers est mis en file lorsqu'un agent termine une intervention" do
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      post terminer_intervention_path(intervention)
    end
  end

  test "le mail de changement de statut aux managers n'est pas mis en file lorsqu'un agent valide une intervention" do
    intervention = interventions(:intervention_terminée)

    assert_no_enqueued_jobs only: NotifManagersWorkflowChangedJob do
      post valider_intervention_path(intervention)
    end
  end

  test "le mail de changement de statut aux managers n'est pas mis en file lorsqu'un agent refuse une intervention" do
    intervention = interventions(:intervention_terminée)

    assert_no_enqueued_jobs only: NotifManagersWorkflowChangedJob do
      post refuser_intervention_path(intervention)
    end
  end

  test "le mail de changement de statut aux managers n'est pas mis en file lorsqu'un agent archive une intervention" do
    intervention = interventions(:intervention_validé)

    assert_no_enqueued_jobs only: NotifManagersWorkflowChangedJob do
      post archiver_intervention_path(intervention)
    end
  end

  # test "NotifManagersWorkflowChangedJob n'est pas mis en file d'attente si un agent modifie le statut avec une organisation sans manager" do
  #   sign_in users(:john_wick)
  #   intervention = interventions(:intervention_sans_manager)
  #
  #   assert_enqueued_jobs 0 do
  #     post terminer_intervention_path(intervention)
  #   end
  # end

  # Permet de tester quand un manager termine une intervention, que ca ne notifie pas les manager, comme lui-même est un utilisateur
  test "le mail de changement de statut aux managers n'est pas mis en file lorsqu'un manager termine lui-même une intervention" do
    sign_in users(:manager_marseille)
    intervention = interventions(:nettoyage_port)

    assert_no_enqueued_jobs only: NotifManagersWorkflowChangedJob do
      post terminer_intervention_path(intervention)
    end
  end
end
