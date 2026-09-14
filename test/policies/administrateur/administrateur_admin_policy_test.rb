# frozen_string_literal: true

require 'test_helper'

class AdministrateurAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    @policy = AdminPolicy.new(administrateur, :admin)
  end

  test "accès autorisé pour un administrateur sur l'espace admin" do
    assert @policy.audits?
    assert @policy.create_new_user?
    assert @policy.create_new_user_do?
    assert @policy.parametres?
  end

  test "accès interdit pour un administrateur sur l'espace admin" do
    refute @policy.stats?
  end
end
