# frozen_string_literal: true

require 'test_helper'

class ManagerCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:manager_paris) # gère service_paris et secretariat

    cotation_son_service = cotations(:cotation_secretariat) # service: secretariat
    cotation_autre_service = cotations(:cotation_paris)       # service: informatique
    cotation_autre_org = cotations(:cotation_marseille)       # mairie_marseille

    @policy = CotationPolicy.new(@manager, cotation_son_service)
    @policy_autre_service = CotationPolicy.new(@manager, cotation_autre_service)
    @policy_autre_org = CotationPolicy.new(@manager, cotation_autre_org)
  end

  test 'index autorisé pour un manager' do
    assert @policy.index?
  end

  test 'show / update / destroy / pdf autorisés sur une cotation de son service' do
    assert @policy.show?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.pdf?
  end

  test 'create autorisé sur une cotation de son service' do
    assert @policy.create?
  end

  test "accès interdit sur une cotation d'un service qu'il ne gère pas" do
    refute @policy_autre_service.show?
    refute @policy_autre_service.update?
    refute @policy_autre_service.destroy?
    refute @policy_autre_service.create?
  end

  test "accès interdit sur une cotation d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.destroy?
  end

  test "scope : un manager ne voit que les cotations des services qu'il gère" do
    scope = CotationPolicy::Scope.new(@manager, Cotation.all).resolve
    assert_includes scope, cotations(:cotation_secretariat) # service secretariat, géré
    refute_includes scope, cotations(:cotation_paris)        # service informatique, non géré
    refute_includes scope, cotations(:cotation_marseille)    # autre organisation
  end
end
