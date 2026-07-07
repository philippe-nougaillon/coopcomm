# frozen_string_literal: true

require 'test_helper'

class UserNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(nil, mail)
  end

  test "accès interdit pour un utilisateur avec l'index d'une newsletter" do
    refute @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un utilisateur avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un utilisateur avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end
