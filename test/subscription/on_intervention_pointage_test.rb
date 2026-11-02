# frozen_string_literal: true

require 'test_helper'

class OnInterventionPointageTest < ActionDispatch::IntegrationTest
  test "le mail de pointage à l'adhérent est mis en file lorsqu'une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:intervention_repete)

    assert_enqueued_with(job: NotifMailAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end

  test "le WhatsApp de pointage à l'adhérent est mis en file lorsqu'une intervention est pointée" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:intervention_repete)

    assert_enqueued_with(job: NotifWhatsappAdherentInterventionPointageJob) do
      get pointer_intervention_path(intervention)
    end
  end
end
