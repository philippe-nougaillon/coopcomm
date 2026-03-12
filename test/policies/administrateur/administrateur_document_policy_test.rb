require "test_helper"

class AdministrateurDocumentPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur_paris = users(:administrateur_paris)
    
    document = documents(:carte_grise)

    @policy = DocumentPolicy.new(administrateur_paris, document)
  end

  # Valider
  test "accès administrateur document valider autorisé" do
    assert @policy.valider?
  end

  # Refuser
  test "accès administrateur document refuser autorisé" do
    assert @policy.refuser?
  end
end
