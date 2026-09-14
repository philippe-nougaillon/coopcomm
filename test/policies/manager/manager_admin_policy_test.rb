# frozen_string_literal: true

require 'test_helper'

class ManagerAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    @policy = AdminPolicy.new(manager, :admin)
  end

  test "accès autorisé pour un manager sur l'espace admin" do
    assert @policy.audits?
    assert @policy.create_new_user?
    assert @policy.create_new_user_do?
  end

  test "accès interdit pour un manager sur l'espace admin" do
    refute @policy.parametres?
    refute @policy.stats?
  end
end
