# frozen_string_literal: true

require 'test_helper'

# ApplicationPolicy refuse tout par défaut : c'est ce défaut qui protège une
# policy fille qui oublierait de redéfinir une action.
class ApplicationPolicyDefaultsTest < ActiveSupport::TestCase
  setup do
    @administrateur = users(:administrateur_paris)
    @intervention = interventions(:tonte_locaux)
    @policy = ApplicationPolicy.new(@administrateur, @intervention)
  end

  test 'index? est refusé par défaut' do
    assert_not @policy.index?
  end

  test 'show? est refusé par défaut' do
    assert_not @policy.show?
  end

  test 'create? est refusé par défaut' do
    assert_not @policy.create?
  end

  test 'new? délègue à create? et est donc refusé par défaut' do
    assert_not @policy.new?
  end

  test 'update? est refusé par défaut' do
    assert_not @policy.update?
  end

  test 'edit? délègue à update? et est donc refusé par défaut' do
    assert_not @policy.edit?
  end

  test 'destroy? est refusé par défaut' do
    assert_not @policy.destroy?
  end

  test 'organisation? est vrai quand le record et l\'utilisateur partagent l\'organisation' do
    assert @policy.organisation?
  end

  test 'organisation? est faux pour un record d\'une autre organisation' do
    policy = ApplicationPolicy.new(@administrateur, interventions(:nettoyage_port))

    assert_not policy.organisation?
  end

  test 'organisation? est faux sans utilisateur connecté' do
    policy = ApplicationPolicy.new(nil, @intervention)

    assert_not policy.organisation?
  end
end
