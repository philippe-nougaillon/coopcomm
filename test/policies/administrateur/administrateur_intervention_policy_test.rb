# frozen_string_literal: true

require 'test_helper'

class AdministrateurInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)

    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(administrateur_paris, intervention_paris)
  end

  # Index
  test 'should get index' do
    assert @policy.index?
  end

  # Show
  test 'should get show' do
    assert @policy.show?
  end

  # New
  test 'should get new' do
    assert @policy.new?
  end

  # Create
  test 'should get create' do
    assert @policy.create?
  end

  # Edit
  test 'should get edit' do
    assert @policy.edit?
  end

  # Update
  test 'should get update' do
    assert @policy.update?
  end

  # Destroy
  test 'should get destroy' do
    assert @policy.destroy?
  end

  # Purge
  test 'should get purge' do
    assert @policy.purge?
  end

  # Get_unavailable_elements
  test 'should get get_unavailable_elements' do
    assert @policy.get_unavailable_elements?
  end

  # Modèle de pointage
  test 'should get new_intervention_modele_pointage' do
    assert @policy.new_intervention_modele_pointage?
  end

  test 'create_intervention_modele_pointage délègue à new_intervention_modele_pointage' do
    assert @policy.create_intervention_modele_pointage?
  end
end
