# frozen_string_literal: true

require 'test_helper'

class AdherentWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    @policy = WikiPagePolicy.new(adherent, wiki_pages(:blog_public))
    @policy_privée = WikiPagePolicy.new(adherent, wiki_pages(:blog_privé))
    @policy_non_publiée = WikiPagePolicy.new(adherent, wiki_pages(:blog_non_publié))
  end

  test 'accès autorisé pour un adhérent sur une documentation publiée et publique' do
    assert @policy.index?
    assert @policy.blog?
    assert @policy.guide?
    assert @policy.faq?
    assert @policy.show?
  end

  test 'accès interdit pour un adhérent sur une documentation publiée et publique' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  test 'accès autorisé pour un adhérent sur une documentation privée' do
    assert @policy_privée.show?
  end

  test 'accès interdit pour un adhérent sur une documentation non publiée' do
    refute @policy_non_publiée.show?
  end
end
