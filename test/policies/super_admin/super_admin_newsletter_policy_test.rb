# frozen_string_literal: true

require 'test_helper'

class SuperAdminNewsletterPolicyTest < ActionDispatch::IntegrationTest
  def setup
    super_admin = users(:philippe_super_admin)

    # Permet à l'utilisateur philippe_super_admin d'être considéré comme un super admin automatiquement
    ENV['SUPER_ADMIN'] = super_admin.email

    mail = newsletters(:bond)

    @policy = NewsletterPolicy.new(super_admin, mail)
  end

  test "accès autorisé pour un super admin avec l'index d'une newsletter" do
    assert @policy.index?
  end

  # Il peut créer ou supprimer car n'importe qui peut s'abonner et se désabonner, le slug est présent pour la sécurité

  test "accès autorisé pour un super admin avec la création d'une newsletter" do
    assert @policy.new?
  end

  test "accès autorisé pour un super admin avec la suppression d'une newsletter" do
    assert @policy.destroy?
  end
end
