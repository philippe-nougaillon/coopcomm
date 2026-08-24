# frozen_string_literal: true

require 'application_system_test_case'

# Connexion et déconnexion : chaque test pose lui-même son état de départ, la
# moitié d'entre eux ayant justement besoin de commencer déconnecté.
class DeviseAdherentFlowTest < ApplicationSystemTestCase
  setup do
    @adherent = users(:weil)
  end

  test "En tant qu'adhérent, je veux me connecter depuis la page publique" do
    visit root_path
    cliquer_lien_navbar 'Se connecter'

    assert_current_path new_user_session_path
    assert_selector 'h1', text: 'Connexion'

    fill_in 'user_email', with: @adherent.email
    fill_in 'user_password', with: 'qtDug$d843sqACz?V'
    cliquer_bouton 'Se connecter'

    assert_notification 'Vous êtes connecté(e).'
    assert_current_path root_path

    visit interventions_url
    assert_current_path interventions_path
  end

  test "En tant qu'adhérent, je ne peux pas me connecter avec un mot de passe incorrect" do
    visit new_user_session_path

    fill_in 'user_email', with: @adherent.email
    fill_in 'user_password', with: 'mot-de-passe-oublié'
    cliquer_bouton 'Se connecter'

    assert_notification 'Email ou mot de passe incorrect.'

    visit interventions_url
    assert_current_path new_user_session_path
  end

  test "En tant qu'adhérent, je veux me déconnecter" do
    login(@adherent)
    fermer_notification

    se_deconnecter

    visit interventions_url
    assert_current_path new_user_session_path
  end

  test "En tant qu'adhérent, je ne veux pas me déconnecter si j'annule" do
    login(@adherent)
    fermer_notification

    cliquer_bouton_deconnexion
    cliquer_bouton 'Annuler'

    assert_no_selector '#logout_modal', visible: true

    visit interventions_url
    assert_current_path interventions_path
  end
end
