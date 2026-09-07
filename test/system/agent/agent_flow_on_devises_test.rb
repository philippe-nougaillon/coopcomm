# frozen_string_literal: true

require 'application_system_test_case'

class AgentFlowOnDevisesTest < ApplicationSystemTestCase
  setup do
    @agent = users(:bond)
  end

  test "En tant qu'agent, je veux me connecter depuis la page publique" do
    visit root_path
    cliquer_lien_navbar 'Se connecter'

    assert_current_path new_user_session_path
    assert_selector 'h1', text: 'Connexion'

    fill_in 'user_email', with: @agent.email
    fill_in 'user_password', with: 'qtDug$d843sqACz?V'

    assert_equal 'password', find('#user_password')[:type]
    find("[data-action*='password-visibility#toggle']").click
    assert_equal 'text', find('#user_password')[:type]

    cliquer_bouton 'Se connecter'

    assert_notification 'Vous êtes connecté(e).'
    assert_current_path root_path

    visit interventions_url
    assert_current_path interventions_path
  end

  test "En tant qu'agent, je veux me déconnecter" do
    login(@agent)
    fermer_notification

    se_deconnecter

    visit interventions_url
    assert_current_path new_user_session_path
  end

  test "En tant qu'agent, je ne veux pas me déconnecter si j'annule" do
    login(@agent)
    fermer_notification

    cliquer_bouton_deconnexion
    cliquer_bouton 'Annuler'

    assert_no_selector '#logout_modal', visible: true

    visit interventions_url
    assert_current_path interventions_path
  end
end
