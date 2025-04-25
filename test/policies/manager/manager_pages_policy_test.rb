require "test_helper"

class ManagerPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(manager_paris, nil)
  end

  # Assistant
  test "accès autorisé pour un manager pour un assistant de pages" do
    assert @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un manager pour un dashboard de pages" do
    assert @policy.dashboard?
  end
end
