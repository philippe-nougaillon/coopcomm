require "test_helper"

class AdherentWorkflowStateInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @intervention_paris = interventions(:intervention_paris)
    @adherent_marseille = users(:adherent_marseille)
    sign_in users(:patrick_adherent_paris)
  end

  # Terminer
  test "should get terminer" do
    get terminer_intervention_url(@intervention_paris)
    assert_redirected_to @intervention_paris
  end

  test "should redirect to root after get terminer with wrong organisation" do
    sign_in @adherent_marseille

    get terminer_intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # Valider
  test "should get valider" do
    get valider_intervention_url(@intervention_paris)
    assert_redirected_to @intervention_paris
  end

  test "should redirect to root after get valider with wrong organisation" do
    sign_in @adherent_marseille

    get valider_intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # Refuser
  test "should get refuser" do
    get refuser_intervention_url(@intervention_paris)
    assert_redirected_to @intervention_paris
  end

  test "should redirect to root after get refuser with wrong organisation" do
    sign_in @adherent_marseille

    get refuser_intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # Archiver
  test "should get archiver" do
    get archiver_intervention_url(@intervention_paris)
    assert_redirected_to @intervention_paris
  end

  test "should redirect to root after get archiver with wrong organisation" do
    sign_in @adherent_marseille

    get archiver_intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

end
