# frozen_string_literal: true

require 'test_helper'

class AdministrateurPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris) # mairie_paris

    prestation = prestations(:nettoyage_bureaux)              # mairie_paris
    prestation_autre_org = prestations(:prestation_marseille) # mairie_marseille

    @policy = PrestationPolicy.new(@administrateur, prestation)
    @policy_autre_org = PrestationPolicy.new(@administrateur, prestation_autre_org)
  end

  test 'new / create autorisés pour un administrateur' do
    assert @policy.new?
    assert @policy.create?
  end

  test 'edit / update / destroy autorisés dans son organisation' do
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test 'accès interdit dans une autre organisation' do
    refute @policy_autre_org.edit?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
  end

  test 'scope : un administrateur ne voit que les prestations de son organisation' do
    scope = PrestationPolicy::Scope.new(@administrateur, Prestation.all).resolve
    assert_includes scope, prestations(:nettoyage_bureaux)
    refute_includes scope, prestations(:prestation_marseille)
  end
end
