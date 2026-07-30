# frozen_string_literal: true

require 'test_helper'

class AbsencePolicyTest < ActionDispatch::IntegrationTest
  setup do
    @absence = absences(:one) # appartient à bond (agent, Mairie de Paris)
  end

  test 'un agent ne peut pas supprimer sa propre absence' do
    refute AbsencePolicy.new(users(:bond), @absence).destroy?
  end

  test 'un agent ne peut ni créer ni modifier une absence le concernant' do
    refute AbsencePolicy.new(users(:bond), @absence).create?
    refute AbsencePolicy.new(users(:bond), @absence).update?
  end

  test 'un manager de la même équipe peut créer et modifier une absence' do
    assert AbsencePolicy.new(users(:hidalgo), @absence).create?
    assert AbsencePolicy.new(users(:hidalgo), @absence).update?
  end

  test 'un manager de la même équipe peut supprimer une absence' do
    assert AbsencePolicy.new(users(:hidalgo), @absence).destroy?
  end

  test "un manager d'une autre organisation ne peut pas supprimer une absence" do
    refute AbsencePolicy.new(users(:manager_marseille), @absence).destroy?
  end

  test 'un adhérent ne peut pas supprimer l’absence d’un agent' do
    refute AbsencePolicy.new(users(:weil), @absence).destroy?
  end
end
