# frozen_string_literal: true

require 'application_system_test_case'

class InterventionsFormulaireTest < ApplicationSystemTestCase
  test 'les dates réelles déclenchent la vérification live même sur une intervention passée' do
    login(users(:administrateur_paris))

    visit edit_intervention_url(interventions(:tonte_locaux))

    assert_selector "input[name='intervention[début]']" \
                    "[data-verification-disponibilites-target='debut']", visible: :all
    assert_selector "input[name='intervention[début]']" \
                    "[data-action*='verification-disponibilites#verificationWithInput']", visible: :all
  end

  test 'le formulaire agent en création est câblé sur les dates réelles et les agents' do
    login(users(:martin_technique_paris))

    visit new_intervention_url

    assert_selector "form[data-controller~='verification-disponibilites']", visible: :all
    assert_selector "input[name='intervention[début]']" \
                    "[data-verification-disponibilites-target='debut']", visible: :all
    assert_selector "input[name='intervention[début]']" \
                    "[data-action*='verification-disponibilites#verificationWithInput']", visible: :all
    assert_selector "select[name='intervention[agent_ids][]']" \
                    "[data-verification-disponibilites-target='agents']", visible: :all
    assert_no_selector "input[name='intervention[début_prévue]']", visible: :all
  end

  test 'le formulaire agent en édition est câblé sur la date de fin réelle' do
    login(users(:martin_technique_paris))

    visit edit_intervention_url(interventions(:nouvelle_intervention))

    assert_selector "form[data-controller~='verification-disponibilites']", visible: :all
    assert_selector "input[name='intervention[fin]']" \
                    "[data-verification-disponibilites-target='fin']", visible: :all
  end
end
