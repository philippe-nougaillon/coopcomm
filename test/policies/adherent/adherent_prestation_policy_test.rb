# frozen_string_literal: true

require 'test_helper'

# Rôles sans aucun droit sur le catalogue de prestations (adhérent et agent).
class AdherentPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @prestation = prestations(:nettoyage_bureaux)
  end

  test 'un adhérent ne peut pas gérer le catalogue' do
    policy = PrestationPolicy.new(@adherent, @prestation)
    refute policy.new?
    refute policy.create?
    refute policy.edit?
    refute policy.update?
    refute policy.destroy?
  end

  test 'un agent ne peut pas gérer le catalogue' do
    policy = PrestationPolicy.new(@agent, @prestation)
    refute policy.new?
    refute policy.create?
    refute policy.edit?
    refute policy.update?
    refute policy.destroy?
  end
end
