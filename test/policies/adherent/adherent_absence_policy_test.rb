# frozen_string_literal: true

require 'test_helper'

class AdherentAbsencePolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    absence = absences(:one)

    @policy = AbsencePolicy.new(adherent, absence)
  end

  test "accès interdit pour un adhérent sur l'absence d'un agent" do
    refute @policy.create?
    refute @policy.update?
    refute @policy.destroy?
  end
end
