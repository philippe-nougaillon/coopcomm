# frozen_string_literal: true

require 'test_helper'

class ManagerAbsencePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    absence = absences(:one)

    @policy = AbsencePolicy.new(manager, absence)
    @policy_autre_service = AbsencePolicy.new(users(:manager_paris), absence)
    @policy_autre_org = AbsencePolicy.new(users(:manager_marseille), absence)
  end

  test "accès autorisé pour un manager sur une absence d'un agent de son service" do
    assert @policy.create?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès interdit pour un manager sur une absence d'un agent d'un service qu'il ne gère pas" do
    refute @policy_autre_service.create?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
  end

  test "accès interdit pour un manager sur une absence d'une autre organisation" do
    refute @policy_autre_org.create?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end
end
