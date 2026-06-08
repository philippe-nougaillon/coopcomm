require "test_helper"

# Rôles sans aucun droit de gestion des cotations (adhérent et agent regroupés).
class AdherentCotationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @adherent = users(:weil)
    @agent = users(:agent_whatsapp)
    @cotation = cotations(:cotation_paris)
  end

  test "un adhérent n'a aucun accès aux cotations" do
    policy = CotationPolicy.new(@adherent, @cotation)
    refute policy.index?
    refute policy.new?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
    refute policy.envoyer?
    refute policy.valider?
    refute policy.refuser?
  end

  test "un agent n'a aucun accès aux cotations" do
    policy = CotationPolicy.new(@agent, @cotation)
    refute policy.index?
    refute policy.new?
    refute policy.show?
    refute policy.create?
    refute policy.update?
    refute policy.destroy?
    refute policy.pdf?
  end

  test "scope : aucune cotation visible pour un adhérent" do
    assert_empty CotationPolicy::Scope.new(@adherent, Cotation.all).resolve
  end

  test "scope : aucune cotation visible pour un agent" do
    assert_empty CotationPolicy::Scope.new(@agent, Cotation.all).resolve
  end
end
