require "test_helper"

class ManagerPagesPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager_paris = users(:hidalgo)

    # Pas de model pour pages, donc valeur nil
    @policy = PagesPolicy.new(manager_paris, nil)
  end

  # Assistant
  test "accès interdit pour un manager sur la page assistant" do
    assert @policy.assistant?
  end

  # Dashboard
  test "accès autorisé pour un manager sur la page dashboard" do
    assert @policy.dashboard?
  end

  # Home
  test "accès autorisé pour un manager sur la page home" do
    assert @policy.home?
  end

  # Meteo
  test "accès autorisé pour un manager sur la page meteo" do
    assert @policy.meteo?
  end

  # meteo_by_day
  test "accès autorisé pour un manager sur la page meteo_by_day" do
    assert @policy.meteo_by_day?
  end
end
