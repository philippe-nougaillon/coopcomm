# frozen_string_literal: true

require 'test_helper'

class AdministrateurPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris)

    prestation = prestations(:nettoyage_bureaux)
    prestation_autre_org = prestations(:prestation_marseille)

    @policy = PrestationPolicy.new(@administrateur, prestation)
    @policy_autre_org = PrestationPolicy.new(@administrateur, prestation_autre_org)
  end

  test 'accès autorisé pour un administrateur sur une prestation de son organisation' do
    assert @policy.new?
    assert @policy.create?
    assert @policy.show?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès interdit pour un administrateur sur une prestation d'une autre organisation" do
    refute @policy_autre_org.show?
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
