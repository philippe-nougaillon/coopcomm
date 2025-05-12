require "test_helper"

class UserInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @intervention_paris = interventions(:intervention_paris)
  end

  test "should get pointer" do
    get pointer_intervention_url(@intervention_paris)
    assert_redirected_to pointage_statut_intervention_path(Intervention.last)
  end
  
  test "should get pointage statut" do
    get pointage_statut_intervention_url(@intervention_paris)
    assert_response :success
  end
end