require "test_helper"

class NotifMailAdherentInterventionPointageJobTest < ActionDispatch::IntegrationTest

  test "le job NotifMailAdherentInterventionPointageJob est mis en file d'attente quand une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    assert_enqueued_with(job: NotifMailAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end
end
