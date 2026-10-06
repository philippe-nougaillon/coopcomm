# frozen_string_literal: true

require 'test_helper'

class ManagerCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:hidalgo)

    @policy = CrmPolicy.new(utilisateur, :crm)
  end

  test 'accès interdit pour un manager sur le CRM' do
    refute @policy.index?
  end
end
