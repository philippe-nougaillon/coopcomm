# frozen_string_literal: true

require 'test_helper'

class AgentWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    @policy = WikiPagePolicy.new(agent, wiki_pages(:blog_public))
    @policy_privée = WikiPagePolicy.new(agent, wiki_pages(:blog_privé))
    @policy_non_publiée = WikiPagePolicy.new(agent, wiki_pages(:blog_non_publié))
  end

  test 'accès autorisé pour un agent sur une documentation publiée et publique' do
    assert @policy.index?
    assert @policy.blog?
    assert @policy.guide?
    assert @policy.faq?
    assert @policy.show?
  end

  test 'accès interdit pour un agent sur une documentation publiée et publique' do
    refute @policy.new?
    refute @policy.create?
    refute @policy.edit?
    refute @policy.update?
    refute @policy.destroy?
  end

  # ==================== TESTS CRITIQUES ====================
  # Une documentation privée ou non publiée ne doit jamais s'ouvrir à un agent :
  # c'est la seule barrière une fois l'URL connue.

  test 'accès interdit pour un agent sur une documentation privée (critique)' do
    refute @policy_privée.show?
  end

  test 'accès interdit pour un agent sur une documentation non publiée (critique)' do
    refute @policy_non_publiée.show?
  end

  # ==================== /TESTS CRITIQUES ====================
end
