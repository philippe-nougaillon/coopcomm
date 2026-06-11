# frozen_string_literal: true

require 'test_helper'

class AbsencePolicyTest < ActionDispatch::IntegrationTest
  setup do
    @absence = absences(:one) # appartient à bond (agent, Mairie de Paris)
  end

  test 'le propriétaire peut supprimer sa propre absence' do
    assert AbsencePolicy.new(users(:bond), @absence).destroy?
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
