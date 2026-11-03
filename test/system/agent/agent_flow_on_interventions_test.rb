# frozen_string_literal: true

require 'application_system_test_case'

class AgentFlowOnInterventionsTest < ApplicationSystemTestCase
  setup do
    @agent = users(:martin_technique_paris)

    login(@agent)
    fermer_notification
  end

  test "En tant qu'agent, je veux changer la date d'une intervention sans ressaisir celle de sa fin" do
    intervention = interventions(:nouvelle_intervention)
    début_attendu = intervention.début.change(day: 18)

    visit edit_intervention_path(intervention)

    fill_in 'Date d’intervention', with: Date.new(2024, 4, 18)
    select '17', from: 'intervention_fin_hour'
    cliquer_bouton 'Enregistrer'

    assert_notification 'Intervention modifiée avec succès.'

    intervention.reload
    assert_equal début_attendu, intervention.début
    assert_equal Time.zone.local(2024, 4, 18, 17, 30), intervention.fin
  end
end
