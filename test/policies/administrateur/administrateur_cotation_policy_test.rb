require "test_helper"

class AdministrateurCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @administrateur = users(:administrateur_paris) # mairie_paris

    cotation = cotations(:cotation_paris)              # mairie_paris
    cotation_autre_org = cotations(:cotation_marseille) # mairie_marseille

    @policy = CotationPolicy.new(@administrateur, cotation)
    @policy_autre_org = CotationPolicy.new(@administrateur, cotation_autre_org)
  end

  test "index autorisé pour un administrateur" do
    assert @policy.index?
  end

  test "show / update / destroy / pdf / create autorisés dans son organisation" do
    assert @policy.show?
    assert @policy.update?
    assert @policy.destroy?
    assert @policy.pdf?
    assert @policy.create?
  end

  test "accès interdit sur une cotation d'une autre organisation" do
    refute @policy_autre_org.show?
    refute @policy_autre_org.update?
    refute @policy_autre_org.destroy?
    refute @policy_autre_org.create?
  end
end
