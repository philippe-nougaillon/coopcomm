# frozen_string_literal: true

require 'test_helper'

class AdministrateurWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    wiki_page = wiki_pages(:blog_only_admin)
    wiki_page_autre_auteur = wiki_pages(:blog)
    wiki_page_non_publiée = wiki_pages(:guide)

    @policy = WikiPagePolicy.new(administrateur, wiki_page)
    @policy_autre_auteur = WikiPagePolicy.new(administrateur, wiki_page_autre_auteur)
    @policy_non_publiée = WikiPagePolicy.new(administrateur, wiki_page_non_publiée)
  end

  test 'accès autorisé pour un administrateur sur une page wiki dont il est auteur' do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
    assert @policy.destroy?
  end

  test "accès autorisé pour un administrateur sur une page wiki d'un autre auteur" do
    assert @policy_autre_auteur.show?
    assert @policy_autre_auteur.edit?
    assert @policy_autre_auteur.update?
  end

  test "accès interdit pour un administrateur sur une page wiki d'un autre auteur" do
    refute @policy_autre_auteur.destroy?
  end

  test 'accès autorisé pour un administrateur sur une page wiki non publiée' do
    assert @policy_non_publiée.show?
  end
end
