# frozen_string_literal: true

require 'test_helper'

class UserNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(nil, newsletter)
  end

  test 'accès autorisé pour un utilisateur non connecté sur un abonnement à la newsletter' do
    assert @policy.new?
    assert @policy.destroy?
  end

  test 'accès interdit pour un utilisateur non connecté sur un abonnement à la newsletter' do
    refute @policy.index?
  end
end
