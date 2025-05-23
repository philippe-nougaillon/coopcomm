require "test_helper"

class AgentNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(agent, mail)
  end

  test "accès interdit pour un agent avec l'index d'une newsletter" do
    refute @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un agent avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un agent avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end