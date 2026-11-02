# frozen_string_literal: true

require 'test_helper'

class ConventionsDeLAnneeTest < ActiveSupport::TestCase
  # ==================== TESTS CRITIQUES ====================
  # Les conventions suivent la visibilité de leur liste (services du manager, organisation de l'administrateur,
  # les siennes pour l'adhérent), et leurs heures sont de l'argent conventionné.
  test 'les conventions d’un manager sont celles de ses services, actives dans l’année, avec leurs heures (critique)' do
    travel_to Time.zone.local(2026, 10, 26, 12) do
      assert_equal [{ service: 'Informatique', adherent: 'Weil Ariel', du: '2026-01-01', au: '2026-12-31',
                      conventionnees: 100.0, consommees: 0.0, prevues: 0.0 }], ConventionsDeLAnnee.call(users(:hidalgo))
    end
  end

  test 'les heures consommées et prévues d’une convention sont sommées sur les interventions de son adhérent et de son service (critique)' do
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Dépannage fait',
                         début: Time.zone.local(2026, 3, 10, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 4)
    Intervention.create!(adherent: users(:weil), service: services(:informatique), description: 'Dépannage prévu',
                         début_prévue: Time.zone.local(2026, 11, 10, 9), fin_prévue: Time.zone.local(2026, 11, 10, 11),
                         workflow_state: Intervention::NOUVEAU)
    Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Tonte hors convention',
                         début: Time.zone.local(2026, 3, 11, 9), workflow_state: Intervention::VALIDE).update_columns(temps_total: 9)

    mesures = travel_to(Time.zone.local(2026, 10, 26, 12)) { ConventionsDeLAnnee.call(users(:weil)) }

    assert_equal 1, mesures.size
    assert_in_delta 4.0, mesures.first[:consommees]
    assert_in_delta 2.0, mesures.first[:prevues]
  end

  test 'un adhérent ne reçoit pas les conventions des autres adhérents (critique)' do
    travel_to Time.zone.local(2026, 10, 26, 12) do
      assert_empty ConventionsDeLAnnee.call(users(:berthout))
    end
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une convention qui ne recouvre pas l’année en cours n’est pas retenue' do
    travel_to Time.zone.local(2027, 3, 1, 12) do
      assert_empty ConventionsDeLAnnee.call(users(:hidalgo))
    end
  end
end
