require "test_helper"

class NotifWhatsappAdherentInterventionPointageJobTest < ActionDispatch::IntegrationTest

  test "le job NotifWhatsappAdherentInterventionPointageJob est mis en file d'attente quand une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)
    
    assert_enqueued_with(job: NotifWhatsappAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end
end
