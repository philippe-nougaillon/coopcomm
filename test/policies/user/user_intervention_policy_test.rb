require "test_helper"

class UserInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @intervention_mère = interventions(:intervention_repete)
  end

  test "should get pointer" do
    sign_in users(:martin_technique_paris)
    get pointer_intervention_url(@intervention_mère)
    assert_redirected_to pointage_statut_intervention_path(Intervention.last)
  end
  
  test "should get pointage statut" do
    sign_in users(:martin_technique_paris)
    # Pointage de l'intervention mère
    get pointer_intervention_url(@intervention_mère)
    
    intervention_enfant = Intervention.find_by(template_slug: @intervention_mère.slug)

    get pointage_statut_intervention_url(intervention_enfant)
    assert_response :success
  end
end