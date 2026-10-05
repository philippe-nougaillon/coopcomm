# frozen_string_literal: true

require 'test_helper'

class AdministrateurCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:administrateur_paris)

    @policy = CrmPolicy.new(utilisateur, :crm)
  end

  test 'accès interdit pour un administrateur sur le CRM' do
    refute @policy.index?
  end
end
