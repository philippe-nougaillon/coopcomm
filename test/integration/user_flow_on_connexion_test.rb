# frozen_string_literal: true

require 'test_helper'

class UserFlowOnConnexionTest < ActionDispatch::IntegrationTest
  setup do
    @utilisateur = users(:weil)
  end

  test 'un mot de passe incorrect est refusé, puis le bon mot de passe connecte' do
    get root_path

    assert_response :success
    assert_dom "a[href=?]", new_user_session_path

    get new_user_session_path

    assert_response :success
    assert_dom 'h1', text: 'Connexion'

    se_connecter_avec 'mot-de-passe-oublié'

    assert_response :unprocessable_content
    assert_equal 'Email ou mot de passe incorrect.', flash[:alert]

    get interventions_url
    assert_redirected_to new_user_session_path

    se_connecter_avec 'qtDug$d843sqACz?V'

    # Devise ramène sur la page demandée avant la connexion, pas sur l'accueil.
    assert_redirected_to interventions_path
    assert_equal 'Vous êtes connecté(e).', flash[:notice]

    follow_redirect!
    assert_response :success
  end

  private

  def se_connecter_avec(mot_de_passe)
    post user_session_path, params: { user: { email: @utilisateur.email, password: mot_de_passe } }
  end
end
