# frozen_string_literal: true

require 'test_helper'

class UserWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @policy = WikiPagePolicy.new(nil, wiki_pages(:blog_public))
    @policy_privée = WikiPagePolicy.new(nil, wiki_pages(:blog_privé))
    @policy_non_publiée = WikiPagePolicy.new(nil, wiki_pages(:blog_non_publié))
  end

  test 'accès autorisé pour un utilisateur non connecté sur une documentation publiée et publique' do
    assert @policy.index?
    assert @policy.blog?
    assert @policy.guide?
    assert @policy.faq?
    assert @policy.show?
  end

  test 'accès interdit pour un utilisateur non connecté sur une documentation publiée et publique' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  # ==================== TESTS CRITIQUES ====================
  # La documentation est le seul écran ouvert au public : une page privée ou non
  # publiée qui s'y afficherait sortirait de l'organisation.

  test 'accès interdit pour un utilisateur non connecté sur une documentation privée (critique)' do
    refute @policy_privée.show?
  end

  test 'accès interdit pour un utilisateur non connecté sur une documentation non publiée (critique)' do
    refute @policy_non_publiée.show?
  end

  # ==================== /TESTS CRITIQUES ====================
end
