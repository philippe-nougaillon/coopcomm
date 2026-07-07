# frozen_string_literal: true

require 'test_helper'

class AgentWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent_paris = users(:martin_technique_paris)

    wiki_page = wiki_pages(:blog)

    @policy = WikiPagePolicy.new(agent_paris, wiki_page)
  end

  # New
  test 'accès interdit pour un agent pour un new de wiki pages' do
    refute @policy.new?
  end

  # Create
  test 'accès interdit pour un agent pour un create de wiki pages' do
    refute @policy.create?
  end

  # Edit
  test 'accès interdit pour un agent pour un edit de wiki pages' do
    refute @policy.edit?
  end

  # Update
  test 'accès interdit pour un agent pour un update de wiki pages' do
    refute @policy.update?
  end

  # Destroy
  test 'accès interdit pour un agent pour un destroy de wiki pages' do
    refute @policy.destroy?
  end
end
