require "test_helper"

class NotifAdherentInterventionTermineeJobTest < ActionDispatch::IntegrationTest

  test "le job est mis en file d'attente quand un agent termine une intervention avec un adhérent" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    
    assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
      get terminer_intervention_path(intervention)
    end
  end

  test "le job est mis en file d'attente quand une équipe termine une intervention avec un adhérent" do
    sign_in users(:nettoyage)
    intervention = interventions(:nouvelle_intervention)
    
    assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
      get terminer_intervention_path(intervention)
    end
  end
end
