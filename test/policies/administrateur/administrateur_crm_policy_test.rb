# frozen_string_literal: true

require 'test_helper'

class AdministrateurCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:administrateur_paris)

    @policy = CrmPolicy.new(utilisateur, :crm)
  end

  test 'accès autorisé pour un administrateur sur le CRM' do
    assert @policy.index?
  end
end
