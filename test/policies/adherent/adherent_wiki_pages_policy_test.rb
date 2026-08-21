# frozen_string_literal: true

require 'test_helper'

class AdherentWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    wiki_page_publique = wiki_pages(:wiki_page_publique)
    wiki_page_privée = wiki_pages(:blog)
    wiki_page_non_publiée = wiki_pages(:guide)

    @policy = WikiPagePolicy.new(adherent, wiki_page_publique)
    @policy_privée = WikiPagePolicy.new(adherent, wiki_page_privée)
    @policy_non_publiée = WikiPagePolicy.new(adherent, wiki_page_non_publiée)
  end

  test 'accès autorisé pour un adhérent sur une page wiki publique' do
    assert @policy.index?
    assert @policy.show?
  end

  test 'accès interdit pour un adhérent sur une page wiki publique' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test 'accès interdit pour un adhérent sur une page wiki privée' do
    refute @policy_privée.show?
  end

  test 'accès interdit pour un adhérent sur une page wiki non publiée' do
    refute @policy_non_publiée.show?
  end
end
