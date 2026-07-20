# frozen_string_literal: true

require 'test_helper'

# Anti-régression R3 (cf. `.claude/method/bugs-signales.md`).
#
# `sign_in` empile un bloc dans une file GLOBALE AU PROCESSUS que Warden draine
# à la première requête venue, sans filtrer autre chose que les assets. Sous
# `test:all`, une requête navigateur retardataire d'un test système consommait
# ce bloc à la place du test d'intégration suivant, qui partait alors non
# authentifié (302 vers /users/sign_in au lieu du comportement métier).
# 5 occurrences en 2 jours, sur 5 tests différents : la victime dépend du seed.
#
# Le correctif vit dans `test_helper.rb` (file invisible hors du thread de test).
# Ces tests le verrouillent : ils échouent si quelqu'un le retire.
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
    # Garde anti-faux-positif : le correctif ne doit pas neutraliser `sign_in`
    # lui-même (une file toujours vide ferait passer les deux tests ci-dessus
    # tout en cassant l'authentification de toute la suite).
    sign_in users(:hidalgo)

    assert_equal 1, Warden._on_next_request.size, 'le hook doit être posé dans le thread de test'
  end
end
