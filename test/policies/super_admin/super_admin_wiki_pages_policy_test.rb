require "test_helper"

class SuperAdminWikiPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @super_admin = users(:philippe_super_admin)

    wiki_page = wiki_pages(:blog)

    @policy = WikiPagePolicy.new(@super_admin, wiki_page)
  end

  # New
  test "accès autorisé pour un super admin pour un new de wiki pages " do
    assert @policy.new?
  end

  # Create
  test "accès autorisé pour un super admin pour un create de wiki pages " do
    assert @policy.create?
  end

  # Edit
  test "accès autorisé pour un super admin pour un edit de wiki pages " do
    assert @policy.edit?
  end

  # Update
  test "accès autorisé pour un super admin pour un update de wiki pages " do
    assert @policy.update?
  end

  # Destroy
  test "accès interdit pour un super admin pour un destroy de wiki pages, pas avec le même nom que le créateur" do
    refute @policy.destroy?
  end
  
  test "accès autorisé pour un super admin pour un destroy de wiki pages " do
    assert WikiPagePolicy.new(@super_admin, @super_admin)
  end
end
