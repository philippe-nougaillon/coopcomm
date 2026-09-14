# frozen_string_literal: true

require 'test_helper'

class AdherentAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    @policy = AdminPolicy.new(adherent, :admin)
  end

  test "accès interdit pour un adhérent sur l'espace admin" do
    refute @policy.audits?
    refute @policy.create_new_user?
    refute @policy.create_new_user_do?
    refute @policy.parametres?
    refute @policy.stats?
  end
end
