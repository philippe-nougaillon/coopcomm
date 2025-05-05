require "test_helper"

class NotifAgentsCommentairesChangedJobTest < ActionDispatch::IntegrationTest
  
  test "le job est lancé quand un adhérent modifie le commentaire" do
    sign_in users(:weil)
    intervention = interventions(:tonte_locaux)
    
    assert_enqueued_with(job: NotifAgentsCommentairesChangedJob) do
      patch intervention_path(intervention), params: {
        intervention: { commentaires: "Passer la tondeuse sur les plantations " }
      }
    end
  end
end
