# frozen_string_literal: true

require 'test_helper'

class AdherentCrmPolicyTest < ActionDispatch::IntegrationTest
  def setup
    utilisateur = users(:weil)

    @policy = CrmPolicy.new(utilisateur, :crm)
  end

  test 'accès autorisé pour un adhérent sur le CRM' do
    assert @policy.index?
  end
end
