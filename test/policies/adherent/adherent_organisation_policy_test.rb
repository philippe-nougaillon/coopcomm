require "test_helper"

class AdherentOrganisationPolicyTest < ActionDispatch::IntegrationTest
  # Le controller organisation n'a pas de page activé, donc pas de policy

  # def setup
  #   adherent_paris = users(:patrick_adherent_paris)
    
  #   organisation = organisations(:mairie_paris)

  #   @policy = OrganisationPolicy.new(adherent_paris, organisation)
  # end

  # # Show
  # test "accès interdit pour un adhérent avec le show d'une organisation" do
  #   refute @policy.show?
  # end

  # # Edit
  # test "accès interdit pour un adhérent avec l'edit d'une organisation" do
  #   refute @policy.edit?
  # end

  # # Update
  # test "accès interdit pour un adhérent avec l'update d'une organisation" do
  #   refute @policy.update?
  # end
end
