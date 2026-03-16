require "test_helper"

class AdministrateurWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)

    wiki_page = wiki_pages(:blog_only_admin)

    @policy = WikiPagePolicy.new(administrateur_paris, wiki_page)
  end

  # New
  test "accès autorisé pour un administrateur pour un new de wiki pages" do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un administrateur pour un create de wiki pages" do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un administrateur pour un edit de wiki pages" do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un administrateur pour un update de wiki pages" do
    assert @policy.update?
  end

  # Destroy
  test "accès autorisé pour un administrateur pour un destroy de wiki pages" do
    assert @policy.destroy?
  end
end
