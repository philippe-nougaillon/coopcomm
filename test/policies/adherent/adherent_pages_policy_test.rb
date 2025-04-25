require "test_helper"

class AdherentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(adherent_paris, nil)
  end

  # Assistant
  test "accès interdit pour un adherent avec un assistant de pages" do
    refute @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un adherent avec un dashboard de pages" do
    assert @policy.dashboard?
  end
end
