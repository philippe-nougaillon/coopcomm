require "test_helper"

class ManagerWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    wiki_page = wiki_pages(:blog)

    @policy = WikiPagePolicy.new(manager, wiki_page)
  end

  # New
  test "accès interdit pour un manager pour un new de wiki pages" do
    refute @policy.new?
  end

  # Create
  test "accès interdit pour un manager pour un create de wiki pages" do
    refute @policy.create?
  end

  # Edit
  test "accès interdit pour un manager pour un edit de wiki pages" do
    refute @policy.edit?
  end

  # Update
  test "accès interdit pour un manager pour un update de wiki pages" do
    refute @policy.update?
  end

  # Destroy
  test "accès interdit pour un manager pour un destroy de wiki pages" do
    refute @policy.destroy?
  end
end
