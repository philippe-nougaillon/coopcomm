# frozen_string_literal: true

require 'test_helper'

class SuperAdminWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    wiki_page_autre_auteur = wiki_pages(:blog)
    wiki_page_non_publiée = wiki_pages(:guide)

    @policy = WikiPagePolicy.new(super_admin, wiki_page_autre_auteur)
    @policy_non_publiée = WikiPagePolicy.new(super_admin, wiki_page_non_publiée)
  end

  test "accès autorisé pour un super admin sur une page wiki d'un autre auteur" do
    assert @policy.index?
    assert @policy.show?
    assert @policy.new?
    assert @policy.create?
    assert @policy.edit?
    assert @policy.update?
  end

  test "accès interdit pour un super admin sur une page wiki d'un autre auteur" do
    refute @policy.destroy?
  end

  test 'accès autorisé pour un super admin sur une page wiki non publiée' do
    assert @policy_non_publiée.show?
  end
end
