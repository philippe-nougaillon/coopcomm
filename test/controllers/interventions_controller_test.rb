require "test_helper"

class InterventionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @intervention = agent_interventions(:bond_tonte_locaux).intervention
    sign_in users(:hidalgo)
  end

  test "should get index" do
    get interventions_url
    assert_response :success
  end

  test "should get new" do
    get new_intervention_url
    assert_response :success
  end

  test "should create intervention" do
    assert_difference("Intervention.count") do
      post interventions_url, params: {
        intervention: {
          organisation_id: @intervention.organisation_id,
          début: @intervention.début,
          fin: @intervention.fin,
          temps_de_pause: @intervention.temps_de_pause,
          description: @intervention.description,
          workflow_state: @intervention.workflow_state,
          adherent_id: @intervention.adherent_id,
          temps_total: @intervention.temps_total,
          commentaires: @intervention.commentaires,
          note: @intervention.note,
          team_id: @intervention.team_id,
          avis: @intervention.avis,
          repeter: @intervention.repeter,
          slug: SecureRandom.uuid,
          début_prévue: @intervention.début_prévue,
          fin_prévue: @intervention.fin_prévue
        }
      }
    end

    assert_redirected_to intervention_url(Intervention.last)
  end

  test "should show intervention" do
    get intervention_url(@intervention)
    assert_response :success
  end

  test "should get edit" do
    get edit_intervention_url(@intervention)
    assert_response :success
  end

  test "should update intervention" do
    patch intervention_url(@intervention), params: {
      intervention: {
        début: @intervention.début,
        fin: @intervention.fin,
        temps_de_pause: @intervention.temps_de_pause,
        description: @intervention.description,
        workflow_state: @intervention.workflow_state,
        temps_total: @intervention.temps_total,
        commentaires: @intervention.commentaires,
        note: @intervention.note,
        avis: @intervention.avis,
        début_prévue: @intervention.début_prévue,
        fin_prévue: @intervention.fin_prévue
      }
    }
    assert_redirected_to intervention_url(@intervention)
  end

  test "should destroy intervention" do
    assert_difference("Intervention.count", -1) do
      delete intervention_url(@intervention)
    end

    assert_redirected_to interventions_url
  end

  test "should redirect to root if intervention doesn't exist" do
    get intervention_url("abcdefg")
    assert_redirected_to root_path
  end

  test "should destroy photo with purge" do
    @intervention.photos.attach(file_fixture("exemple.png"))
    @intervention.save

    assert_difference("@intervention.photos.count", -1) do
      delete purge_intervention_url(@intervention), params: {
        photo_id: @intervention.photos.first.id
      }
    end

    assert_redirected_to @intervention
  end

  test "pointer intervention repete doit créer une intervention" do
    intervention = interventions(:intervention_a_repeter)
    
    assert_difference("Intervention.count", 1) do
      get pointer_intervention_url(intervention)
    end
  end

  test "pointer intervention repete doit mettre fin à une intervention" do
    intervention = interventions(:intervention_a_repeter)
    
    # Pointage
    get pointer_intervention_url(intervention)
    
    intervention_créée = Intervention.find_by(template_slug: intervention.slug)
    
    assert_nil intervention_créée.fin

    # Repointage
    get pointer_intervention_url(intervention)

    intervention_créée.reload
    assert_not_nil intervention_créée
  end

  test "pointer intervention pas repete ne doit pas créer une intervention" do
    intervention = interventions(:intervention_a_repeter)
    intervention.repeter = false
    intervention.save

    assert_no_difference("Intervention.count") do
      get pointer_intervention_url(intervention)
    end
  end
end
