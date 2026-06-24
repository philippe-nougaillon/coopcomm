# frozen_string_literal: true

require 'test_helper'

class OnInterventionPointageTest < ActionDispatch::IntegrationTest
  test "NotifMailAdherentInterventionPointageJob est mis en file d'attente quand une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:intervention_repete)

    assert_enqueued_with(job: NotifMailAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end

  test "NotifWhatsappAdherentInterventionPointageJob est mis en file d'attente quand une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:intervention_repete)

    assert_enqueued_with(job: NotifWhatsappAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end
end
