# frozen_string_literal: true

require 'test_helper'

class SuperAdminPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = super_admin.email

    @policy = PagesPolicy.new(super_admin, nil)
  end

  def teardown
    ENV['SUPER_ADMIN'] = @super_admin_initial
    ENV.delete('SUPER_ADMIN') if @super_admin_initial.nil?
  end

  test 'accès autorisé pour un super admin sur les pages sans record' do
    assert @policy.assistant?
    assert @policy.home?
    assert @policy.meteo?
    assert @policy.meteo_by_day?
  end
end
