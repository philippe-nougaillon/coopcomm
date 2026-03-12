require "test_helper"

class AdministrateurPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(administrateur_paris, nil)
  end

  # Assistant
  test "accès autorisé pour un administrateur pour un assistant de pages" do
    assert @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un administrateur pour un dashboard de pages" do
    assert @policy.dashboard?
  end
end
