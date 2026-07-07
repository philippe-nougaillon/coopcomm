# frozen_string_literal: true

require 'test_helper'

class ManagerNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(manager, mail)
  end

  test "accès interdit pour un manager avec l'index d'une newsletter" do
    refute @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un manager avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un manager avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end
