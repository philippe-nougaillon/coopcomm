# frozen_string_literal: true

require 'test_helper'

class ManagerWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    @policy = WikiPagePolicy.new(manager, wiki_pages(:blog_public))
    @policy_privée = WikiPagePolicy.new(manager, wiki_pages(:blog_privé))
    @policy_non_publiée = WikiPagePolicy.new(manager, wiki_pages(:blog_non_publié))
    @policy_autre_auteur = WikiPagePolicy.new(manager, wiki_pages(:blog_de_l_administrateur))
  end

  test 'accès autorisé pour un manager sur une documentation dont il est l’auteur' do
    assert @policy.index?
    assert @policy.blog?
    assert @policy.guide?
    assert @policy.faq?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test 'accès autorisé pour un manager sur une documentation privée' do
    assert @policy_privée.show?
    assert @policy_privée.edit?
    assert @policy_privée.update?
  end

  test 'accès autorisé pour un manager sur une documentation non publiée' do
    assert @policy_non_publiée.show?
    assert @policy_non_publiée.edit?
    assert @policy_non_publiée.update?
  end

  test 'accès autorisé pour un manager sur une documentation d’un autre auteur' do
    assert @policy_autre_auteur.show?
    assert @policy_autre_auteur.edit?
    assert @policy_autre_auteur.update?
  end

  test 'accès interdit pour un manager sur une documentation d’un autre auteur' do
    refute @policy_autre_auteur.destroy?
  end
end
