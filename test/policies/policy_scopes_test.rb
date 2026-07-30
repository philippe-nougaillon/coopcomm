# frozen_string_literal: true

require 'test_helper'

# Les `Scope#resolve` des policies : la plupart sont des pass-through, jamais
# exercés par les tests de rôle qui n'interrogent que les prédicats.
class PolicyScopesTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # Chaque entrée : la policy et le modèle que son scope résout.
  PASS_THROUGH = {
    AdminPolicy => User,
    DocumentPolicy => Document,
    InterventionPolicy => Intervention,
    MailLogPolicy => MailLog,
    MessageriePolicy => Message,
    MouvementPolicy => Mouvement,
    NewsletterPolicy => Newsletter,
    OrganisationPolicy => Organisation,
    PagesPolicy => Intervention,
    ServicePolicy => Service,
    ToolPolicy => Tool,
    UserPolicy => User,
    WarehousePolicy => Warehouse,
    WikiPagePolicy => WikiPage
  }.freeze

  PASS_THROUGH.each do |policy_class, model|
    test "#{policy_class}::Scope rend le scope reçu tel quel" do
      scope = model.all

      resolved = policy_class::Scope.new(@manager, scope).resolve

      assert_equal scope, resolved
    end
  end

  test 'PrestationPolicy::Scope borne les prestations à l\'organisation de l\'utilisateur' do
    resolved = PrestationPolicy::Scope.new(@manager, Prestation.all).resolve

    assert_includes resolved, prestations(:nettoyage_bureaux)
    assert_not_includes resolved, prestations(:prestation_marseille)
  end

  # Épinglage : `resolve` renvoie la CLASSE Scope, pas une relation (cf. bug
  # B-f signalé). Le CRM n'appelle pas policy_scope, donc sans effet aujourd'hui.
  test 'CrmPolicy::Scope renvoie la classe Scope et non une relation' do
    resolved = CrmPolicy::Scope.new(@manager, Cotation.all).resolve

    assert_equal CrmPolicy::Scope, resolved
    assert_not_kind_of ActiveRecord::Relation, resolved
  end

  test 'ApplicationPolicy::Scope#resolve doit être redéfini' do
    scope = ApplicationPolicy::Scope.new(@manager, User.all)

    assert_raises(NotImplementedError) { scope.resolve }
  end
end
