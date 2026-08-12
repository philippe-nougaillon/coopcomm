# frozen_string_literal: true

require 'test_helper'

class SuperAdminNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = super_admin.email

    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(super_admin, newsletter)
  end

  def teardown
    ENV['SUPER_ADMIN'] = @super_admin_initial
    ENV.delete('SUPER_ADMIN') if @super_admin_initial.nil?
  end

  test 'accès autorisé pour un super admin sur un abonnement à la newsletter' do
    assert @policy.index?
    assert @policy.new?
    assert @policy.destroy?
  end
end
