require "test_helper"

class NotifManagersWorkflowChangedJobTest < ActionDispatch::IntegrationTest

  setup do
    sign_in users(:martin_technique_paris)
  end

  test "le job est mis en file d'attente quand un agent termine une intervention avec un manageur dans l'organisation" do
    intervention = interventions(:nouvelle_intervention)
    
    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      get terminer_intervention_path(intervention)
    end
  end

  test "le job est mis en file d'attente quand un agent valide une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_terminée)
    
    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      get valider_intervention_path(intervention)
    end
  end

  test "le job est mis en file d'attente quand un agent refuse une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_terminée)
    
    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      get refuser_intervention_path(intervention)
    end
  end

  test "le job est mis en file d'attente quand un agent archive une intervention avec un manager dans l'organisation" do
    intervention = interventions(:intervention_validé)

    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      get archiver_intervention_path(intervention)
    end
  end

  test "le job n'est pas mis en file d'attente si un agent modifie le statut avec une organisation sans manager" do
    sign_in users(:john_wick)
    intervention = interventions(:intervention_sans_manage)

    assert_enqueued_jobs 0 do
      get terminer_intervention_path(intervention)
    end
  end

  test "le job n'est pas mis en file d'attente si un manager modifie le statut avec une organisation contenant un manager qui est lui-même" do
    sign_in users(:manager_marseille)
    intervention = interventions(:nettoyage_port)

    assert_enqueued_jobs 0 do
      get terminer_intervention_path(intervention)
    end
  end

  # Tester si manager est lui meme
  # Tester si pas de manager
end
