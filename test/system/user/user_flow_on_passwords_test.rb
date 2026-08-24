# frozen_string_literal: true

require 'application_system_test_case'

# `config.paranoid = true` : Devise renvoie le même message qu'une adresse soit
# connue ou non, pour qu'on ne puisse pas deviner qui a un compte. Seul l'envoi
# effectif du mail distingue les deux cas.
class UserFlowOnPasswordsTest < ApplicationSystemTestCase
  include ActionMailer::TestHelper

  MESSAGE_ENVOI = 'Si votre email existe dans notre base de données, vous recevrez un lien vous permettant de récupérer votre mot de passe.'
  NOUVEAU_MOT_DE_PASSE = 'Rivoli-2026!parisXY'

  setup do
    @utilisateur = users(:bond)
  end

  test "En tant qu'utilisateur, je veux demander à changer mon mot de passe oublié" do
    visit new_user_session_path
    cliquer_lien 'Changer de mot de passe'

    assert_current_path new_user_password_path
    assert_selector 'h1', text: 'Mot de passe oublié'
    assert_field 'user_email'
  end

  test "En tant qu'utilisateur, je veux recevoir un mail pour changer mon mot de passe" do
    visit new_user_password_path
    fill_in 'user_email', with: @utilisateur.email

    assert_emails 1 do
      cliquer_bouton 'Changer de mot de passe'
      assert_notification MESSAGE_ENVOI
    end

    assert_equal [@utilisateur.email], ActionMailer::Base.deliveries.last.to
    assert @utilisateur.reload.reset_password_token, "aucun jeton de réinitialisation n'a été posé"
  end

  test "En tant qu'utilisateur, aucun mail ne part si l'adresse est inconnue" do
    visit new_user_password_path
    fill_in 'user_email', with: 'personne@ville-paris.fr'

    assert_no_emails do
      cliquer_bouton 'Changer de mot de passe'
      assert_notification MESSAGE_ENVOI
    end
  end

  test "En tant qu'utilisateur, le lien reçu par mail m'ouvre le formulaire de changement" do
    visit lien_du_mail_de_reinitialisation

    assert_selector 'h1', text: 'Changer de mot de passe'
    assert_field 'user_password'
    assert_field 'user_password_confirmation'
    assert_equal %w[○ ○ ○ ○ ○], pastilles_des_criteres, 'aucun critère ne doit être validé au départ'
  end

  test "En tant qu'utilisateur, je veux définir un nouveau mot de passe et revenir à l'accueil" do
    visit lien_du_mail_de_reinitialisation

    fill_in 'user_password', with: NOUVEAU_MOT_DE_PASSE
    assert_equal %w[● ● ● ● ●], pastilles_des_criteres, 'les critères remplis doivent être marqués'

    fill_in 'user_password_confirmation', with: NOUVEAU_MOT_DE_PASSE
    cliquer_bouton 'Changer mon mot de passe'

    assert_current_path root_path
    assert @utilisateur.reload.valid_password?(NOUVEAU_MOT_DE_PASSE), "le mot de passe n'a pas été changé"
  end

  test "En tant qu'utilisateur, je ne peux pas reprendre exactement le même mot de passe" do
    visit lien_du_mail_de_reinitialisation

    fill_in 'user_password', with: 'qtDug$d843sqACz?V'
    fill_in 'user_password_confirmation', with: 'qtDug$d843sqACz?V'
    cliquer_bouton 'Changer mon mot de passe'

    assert_selector '#error_explanation'
    assert_field 'user_password', with: ''
  end

  test "En tant qu'utilisateur, je suis alerté si mon mot de passe ne respecte pas les critères" do
    visit lien_du_mail_de_reinitialisation

    fill_in 'user_password', with: 'abcd'
    assert_equal %w[○ ○ ● ○ ○], pastilles_des_criteres, 'seule la minuscule est satisfaite par « abcd »'

    fill_in 'user_password_confirmation', with: 'abcd'
    cliquer_bouton 'Changer mon mot de passe'

    assert_selector '#error_explanation'
    assert_not @utilisateur.reload.valid_password?('abcd'), 'le mot de passe ne doit pas avoir changé'
  end

  private

  # Le jeton en clair ne vit que dans le mail : la colonne en base est un condensat.
  # Seul l'hôte du lien est remplacé, le mail portant celui de la configuration.
  def lien_du_mail_de_reinitialisation
    @utilisateur.send_reset_password_instructions

    mail = ActionMailer::Base.deliveries.last
    corps = mail.multipart? ? mail.parts.map { |part| part.body.decoded }.join("\n") : mail.body.decoded
    lien = corps[%r{https?://\S+/users/password/edit\?reset_password_token=[^"&\s]+}]
    assert lien, "aucun lien de réinitialisation dans le mail"

    URI.parse(lien).request_uri
  end

  # La pastille passe de ○ à ● quand le critère est rempli : c'est le seul signal
  # lisible sans asserter une classe CSS.
  def pastilles_des_criteres
    all('.rule-icon').map(&:text)
  end
end
