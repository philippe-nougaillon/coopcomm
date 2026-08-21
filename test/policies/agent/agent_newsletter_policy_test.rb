# frozen_string_literal: true

require 'test_helper'

class AgentNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(agent, newsletter)
  end

  test 'accès autorisé pour un agent sur un abonnement à la newsletter' do
    assert @policy.new?
    assert @policy.destroy?
  end

  test 'accès interdit pour un agent sur un abonnement à la newsletter' do
    refute @policy.index?
  end
end
