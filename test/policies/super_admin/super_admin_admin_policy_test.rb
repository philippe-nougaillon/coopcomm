# frozen_string_literal: true

require 'test_helper'

class SuperAdminAdminPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = super_admin.email

    @policy = AdminPolicy.new(super_admin, :admin)
  end

  def teardown
    ENV['SUPER_ADMIN'] = @super_admin_initial
    ENV.delete('SUPER_ADMIN') if @super_admin_initial.nil?
  end

  test "accès autorisé pour un super admin sur l'espace admin" do
    assert @policy.stats?
    assert @policy.audits?
    assert @policy.create_new_user?
    assert @policy.create_new_user_do?
    assert @policy.parametres?
  end
end
