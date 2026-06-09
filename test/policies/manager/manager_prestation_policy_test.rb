require "test_helper"

class ManagerPrestationPolicyTest < ActionDispatch::IntegrationTest
  def setup
    @manager = users(:manager_paris)
    prestation = prestations(:nettoyage_bureaux)
    @policy = PrestationPolicy.new(@manager, prestation)
  end

  # Le catalogue est géré dans Paramètres, réservé aux administrateurs.
  test "new interdit pour un manager" do
    refute @policy.new?
  end

  test "create interdit pour un manager" do
    refute @policy.create?
  end

  test "edit interdit pour un manager" do
    refute @policy.edit?
  end

  test "update interdit pour un manager" do
    refute @policy.update?
  end

  test "destroy interdit pour un manager" do
    refute @policy.destroy?
  end
end
