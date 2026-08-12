# frozen_string_literal: true

require 'test_helper'

class ManagerNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(manager, newsletter)
  end

  test 'accès autorisé pour un manager sur un abonnement à la newsletter' do
    assert @policy.new?
    assert @policy.destroy?
  end

  test 'accès interdit pour un manager sur un abonnement à la newsletter' do
    refute @policy.index?
  end
end
