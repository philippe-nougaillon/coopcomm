require "test_helper"

class AdherentPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(adherent_paris, nil)
  end

  # Assistant
  test "accès interdit pour un adherent sur la page assistant" do
    refute @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un adherent sur la page dashboard" do
    assert @policy.dashboard?
  end

  # Home
  test "accès autorisé pour un adherent sur la page home" do
    assert @policy.home?
  end

  # Meteo
  test "accès autorisé pour un adherent sur la page meteo" do
    assert @policy.meteo?
  end

  # meteo_by_day
  test "accès autorisé pour un adherent sur la page meteo_by_day" do
    assert @policy.meteo_by_day?
  end
end
