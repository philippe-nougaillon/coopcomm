# frozen_string_literal: true

require 'test_helper'

class AdministrateurNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    newsletter = newsletters(:bond)

    @policy = NewsletterPolicy.new(administrateur, newsletter)
  end

  test 'accès autorisé pour un administrateur sur un abonnement à la newsletter' do
    assert @policy.new?
    assert @policy.destroy?
  end

  test 'accès interdit pour un administrateur sur un abonnement à la newsletter' do
    refute @policy.index?
  end
end
