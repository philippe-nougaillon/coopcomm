require "test_helper"

class AdministrateurNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(administrateur, mail)
  end

  test "accès interdit pour un administrateur avec l'index d'une newsletter" do
    refute @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un administrateur avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un administrateur avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end