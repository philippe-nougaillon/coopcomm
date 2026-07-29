# frozen_string_literal: true

require 'test_helper'

# Anti-régression R3.
class SignInHookIsolationTest < ActionDispatch::IntegrationTest
  test "une requête hors du thread de test ne consomme pas le hook de sign_in" do
    sign_in users(:hidalgo)

    # Reproduit exactement ce que fait le drain de Warden (warden.rb:39) depuis
    # un thread du serveur Puma : il ne doit rien trouver à voler.
    volé = Thread.new { Warden._on_next_request.shift }.value

    assert_nil volé, 'une requête navigateur a consommé le hook de sign_in du test'
  end

  test "le hook survit à une requête navigateur et authentifie bien le test" do
    sign_in users(:hidalgo)
    Thread.new { Warden._on_next_request.shift }.join # tentative de vol

    get interventions_url

    assert_response :success, 'le test aurait dû rester authentifié malgré la requête navigateur'
  end

  test "dans le thread de test, la file reste bien fonctionnelle" do
    # Garde anti-faux-positif : le correctif ne doit pas neutraliser `sign_in` lui-même.
    sign_in users(:hidalgo)

    assert_equal 1, Warden._on_next_request.size, 'le hook doit être posé dans le thread de test'
  end
end
