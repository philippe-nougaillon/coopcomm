# frozen_string_literal: true

require 'test_helper'

class UserAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @policy = AdminPolicy.new(nil, :admin)
  end

  test "accès interdit pour un utilisateur non connecté sur l'espace admin" do
    refute @policy.audits?
    refute @policy.create_new_user?
    refute @policy.create_new_user_do?
    refute @policy.parametres?
    refute @policy.stats?
  end
end
