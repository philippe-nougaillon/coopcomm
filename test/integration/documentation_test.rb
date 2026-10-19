# frozen_string_literal: true

require 'test_helper'

# Une documentation n'a d'intérêt que si elle se retrouve : ce parcours va de sa
# rédaction jusqu'à la recherche qui doit la ramener.
class DocumentationTest < ActionDispatch::IntegrationTest
  setup do
    @manager = users(:hidalgo)
    sign_in @manager
  end

  test "En tant que manager, je veux créer une documentation et la voir affichée avec son titre et son contenu" do
    documentation = créer_documentation

    assert_redirected_to documentation_url(documentation)
    follow_redirect!

    assert_response :success
    assert_dom '#notification', text: /Documentation créée avec succès/
    assert_dom 'h1', text: /Réserver une salle du centre communal/
    assert_dom 'p', text: /La réservation se fait auprès du secrétariat/
  end

  test "En tant que manager, je veux retrouver la documentation que je viens de créer en cherchant son titre" do
    documentation = créer_documentation

    get documentation_index_url(search: 'salle')

    assert_response :success
    assert_dom 'a[href=?]', documentation_path(documentation), text: documentation.titre
  end

  test "En tant que manager, je veux retrouver la documentation que je viens de créer en cherchant dans son contenu" do
    documentation = créer_documentation

    get documentation_index_url(search: 'secrétariat')

    assert_response :success
    assert_dom 'a[href=?]', documentation_path(documentation), text: documentation.titre
  end

  test "En tant que manager, je veux voir la documentation que je viens de créer listée sur la page de sa catégorie" do
    documentation = créer_documentation

    get guide_documentation_index_url

    assert_response :success
    assert_dom 'a[href=?]', documentation_path(documentation), text: documentation.titre
  end

  private

  def créer_documentation
    get new_documentation_url
    assert_response :success

    post documentation_index_url, params: {
      wiki_page: {
        titre: 'Réserver une salle du centre communal',
        sous_titre: 'La marche à suivre',
        contenu: '<p>La réservation se fait auprès du secrétariat, deux semaines à l’avance.</p>',
        catégorie: 'guide',
        publiée: true,
        private: false,
        poids: 10
      }
    }

    WikiPage.find_by!(titre: 'Réserver une salle du centre communal')
  end
end
