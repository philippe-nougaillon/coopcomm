# frozen_string_literal: true

require 'test_helper'

# Filtre Statut de l'index interventions (#309) : le select est `multiple` →
# params[:workflow_state] est un TABLEAU de libellés humanisés.
class InterventionsIndexStatusFilterTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:hidalgo) # manager, services : service_paris / informatique / technique
  end

  test 'filtre par statut en tableau (forme réelle du select multiple)' do
    get interventions_url, params: { workflow_state: ['Nouveau'] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(interventions(:tonte_locaux)), { count: 0 }
  end

  test 'filtre par plusieurs statuts (multi-select)' do
    get interventions_url, params: { workflow_state: %w[Nouveau Terminé] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(interventions(:intervention_terminée)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(interventions(:tonte_locaux)), { count: 0 }
  end

  test 'filtre par statut « Validé » (fixture tonte_locaux corrigée en minuscule)' do
    get interventions_url, params: { workflow_state: ['Validé'] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(interventions(:tonte_locaux)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { count: 0 }
  end

  test 'un statut vide ([""]) retombe sur le défaut (non archivées)' do
    get interventions_url, params: { workflow_state: [''] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
  end
end
