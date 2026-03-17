require "test_helper"

class OnInterventionDoneTest < ActionDispatch::IntegrationTest

  test "NotifAdherentInterventionTermineeJob mis en file d'attente quand un agent termine une intervention avec un adhérent" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    
    assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
      get terminer_intervention_path(intervention)
    end
  end
end
