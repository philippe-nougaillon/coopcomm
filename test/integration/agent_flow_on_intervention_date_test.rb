# frozen_string_literal: true

require 'test_helper'

class AgentFlowOnInterventionDateTest < ActionDispatch::IntegrationTest
  test "En tant qu'agent, je veux corriger une date refusée sans ressaisir l'heure et la minute" do
    sign_in users(:martin_technique_paris)
    intervention = interventions(:nouvelle_intervention)

    début_avant = intervention.début
    heure_saisie = début_avant.hour + 1
    minute_saisie = début_avant.min + 5
    
    expected = début_avant.change(hour: heure_saisie, min: minute_saisie, sec: 0)
    rejected_début = (Date.current + 1).to_s

    patch intervention_url(intervention), params: {
      intervention: { début: rejected_début,
                      début_hour: heure_saisie, début_minute: minute_saisie }
    }

    assert_response :unprocessable_content
    assert_equal début_avant, intervention.reload.début

    # L'heure et la minute ne doivent pas être effacés (remis à 0)
    assert_dom "select[name='intervention[début_hour]'] option[selected][value=?]", heure_saisie.to_s
    assert_dom "select[name='intervention[début_minute]'] option[selected][value=?]", minute_saisie.to_s

    patch intervention_url(intervention), params: {
      intervention: { début: début_avant.to_date.to_s,
                      début_hour: heure_saisie, début_minute: minute_saisie }
    }

    assert_redirected_to intervention_url(intervention)
    actual = intervention.reload.début
    assert_equal expected, actual
  end
end
