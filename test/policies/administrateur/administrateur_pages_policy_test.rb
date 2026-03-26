require "test_helper"

class AdministrateurPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(administrateur_paris, nil)
  end

  # Assistant
  test "accès interdit pour un administrateur sur la page assistant" do
    assert @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un administrateur sur la page dashboard" do
    assert @policy.dashboard?
  end

  # Home
  test "accès autorisé pour un administrateur sur la page home" do
    assert @policy.home?
  end

  # Meteo
  test "accès autorisé pour un administrateur sur la page meteo" do
    assert @policy.meteo?
  end

  # meteo_by_day
  test "accès autorisé pour un administrateur sur la page meteo_by_day" do
    assert @policy.meteo_by_day?
  end
end
