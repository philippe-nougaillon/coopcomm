# frozen_string_literal: true

require 'test_helper'

class ManagerCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:hidalgo)

    @policy = CrmPolicy.new(utilisateur, :crm)
  end

  test 'accès autorisé pour un manager sur le CRM' do
    assert @policy.index?
  end
end
