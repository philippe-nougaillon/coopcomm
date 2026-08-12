# frozen_string_literal: true

require 'test_helper'

class AdherentNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(adherent, newsletter)
  end

  test 'accès autorisé pour un adhérent sur un abonnement à la newsletter' do
    assert @policy.new?
    assert @policy.destroy?
  end

  test 'accès interdit pour un adhérent sur un abonnement à la newsletter' do
    refute @policy.index?
  end
end
