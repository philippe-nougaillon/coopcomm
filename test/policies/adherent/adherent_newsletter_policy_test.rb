# frozen_string_literal: true

require 'test_helper'

class AdherentNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(adherent, mail)
  end

  test "accès interdit pour un adhérent avec l'index d'une newsletter" do
    refute @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un adhérent avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un adhérent avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end
