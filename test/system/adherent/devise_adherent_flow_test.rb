# frozen_string_literal: true

require 'application_system_test_case'

class DeviseAdherentFlowTest < ApplicationSystemTestCase
  setup do
    login(users(:weil))
    fermer_notification
  end

  test "En tant qu'adhérent, je veux me déconnecter" do
    se_deconnecter

    visit interventions_url
    assert_current_path new_user_session_path
  end

  test "En tant qu'adhérent, je ne veux pas me déconnecter si j'annule" do
    cliquer_bouton_deconnexion
    cliquer_bouton 'Annuler'

    assert_no_selector '#logout_modal', visible: true

    visit interventions_url
    assert_current_path interventions_path
  end
end
