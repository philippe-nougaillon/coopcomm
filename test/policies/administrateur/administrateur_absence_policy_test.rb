# frozen_string_literal: true

require 'test_helper'

class AdministrateurAbsencePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    absence = absences(:one)

    @policy = AbsencePolicy.new(administrateur, absence)
  end

  test "accès autorisé pour un administrateur sur une absence d'un agent de son organisation" do
    assert @policy.create?
    assert @policy.update?
    assert @policy.destroy?
  end
end
