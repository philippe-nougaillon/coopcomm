# frozen_string_literal: true

require 'test_helper'

class AdherentWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    wiki_page = wiki_pages(:blog)

    @policy = WikiPagePolicy.new(adherent_paris, wiki_page)
  end

  # New
  test 'accès interdit pour un adhérent pour un new de wiki pages' do
    refute @policy.new?
  end

  # Create
  test 'accès interdit pour un adhérent pour un create de wiki pages' do
    refute @policy.create?
  end

  # Edit
  test 'accès interdit pour un adhérent pour un edit de wiki pages' do
    refute @policy.edit?
  end

  # Update
  test 'accès interdit pour un adhérent pour un update de wiki pages' do
    refute @policy.update?
  end

  # Destroy
  test 'accès interdit pour un adhérent pour un destroy de wiki pages' do
    refute @policy.destroy?
  end
end
