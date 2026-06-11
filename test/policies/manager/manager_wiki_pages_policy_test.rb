# frozen_string_literal: true

require 'test_helper'

class ManagerWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    wiki_page = wiki_pages(:blog)

    @policy = WikiPagePolicy.new(manager, wiki_page)
  end

  # New
  test 'accès autorisé pour un manager pour un new de wiki pages' do
    assert @policy.new?
  end

  # Create
  test 'accès autorisé pour un manager pour un create de wiki pages' do
    assert @policy.create?
  end

  # Edit
  test 'accès autorisé pour un manager pour un edit de wiki pages' do
    assert @policy.edit?
  end

  # Update
  test 'accès autorisé pour un manager pour un update de wiki pages' do
    assert @policy.update?
  end

  # Destroy
  test 'accès autorisé pour un manager pour un destroy de wiki pages' do
    assert @policy.destroy?
  end
end
