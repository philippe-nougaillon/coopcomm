require "test_helper"

class AdherentInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent_paris = users(:patrick_adherent_paris)
    @intervention_paris = interventions(:intervention_paris)
    @adherent_marseille = users(:adherent_marseille)
    sign_in users(:patrick_adherent_paris)
  end

  # Index
  test "should get index" do
    policy = InterventionPolicy.new(@adherent_paris, @intervention_paris)
    assert policy.index?
    assert policy.show?
    assert policy.new?
    assert policy.create?
    assert policy.edit?
    assert policy.update?
    refute policy.destroy?
  end

  # Show
  test "should get show" do
    get intervention_url(@intervention_paris)
    assert_response :success
  end

  test "should redirect to root after show with wrong organisation" do
    sign_in @adherent_marseille

    get intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # New
  test "should get new" do
    get new_intervention_url
    assert_response :success
  end

  # Create
  test "should get create" do
    post interventions_url, params: intervention_for_params(@intervention_paris)
    assert_redirected_to intervention_url(Intervention.last)
  end

  # Edit
  test "should get edit" do
    get intervention_url(@intervention_paris)
    assert_response :success
  end

  test "should redirect to root after edit with wrong organisation" do
    sign_in @adherent_marseille

    get intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # Update
  test "should update intervention" do
    patch intervention_url(@intervention_paris), params: intervention_for_params(@intervention_paris)
    assert_redirected_to intervention_url(@intervention_paris)
  end

  test "should redirect to root after update with wrong organisation" do
    sign_in @adherent_marseille

    patch intervention_url(@intervention_paris), params: intervention_for_params(@intervention_paris)
    assert_redirected_to root_path
  end

  # Destroy
  test "should redirect to root after destroy with adherent" do
    delete intervention_url(@intervention_paris)
    assert_redirected_to root_path
  end

  # Purge
  test "should destroy photo with purge" do
    @intervention_paris.photos.attach(create_uploaded_photo)
    @intervention_paris.save

    delete purge_intervention_url(@intervention_paris), params: {
      photo_id: @intervention_paris.photos.first.id
    }
    assert_redirected_to @intervention_paris
  end

  test "should redirect to root after get purge with wrong organisation" do
    sign_in @adherent_marseille

    @intervention_paris.photos.attach(create_uploaded_photo)
    @intervention_paris.save

    delete purge_intervention_url(@intervention_paris), params: {
      photo_id: @intervention_paris.photos.first.id
    }
    assert_redirected_to root_path
  end

  # Get_unavailable_elements
  # test "should get get_unavailable_elements" do
  #   get get_unavailable_elements_interventions_url
  #   assert_response :success
  # end

  # Pointer
  test "should get pointer" do
    get pointer_intervention_url(@intervention_paris)
    assert_redirected_to pointage_statut_intervention_path(Intervention.last)
  end
  
  test "should get pointage statut" do
    get pointage_statut_intervention_url(@intervention_paris)
    assert_response :success
  end
end
