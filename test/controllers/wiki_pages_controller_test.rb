# frozen_string_literal: true

require 'test_helper'

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrateur = users(:administrateur_paris)
    @documentation = wiki_pages(:blog_de_l_administrateur)
    @documentation_privée = wiki_pages(:blog_privé)
    @documentation_non_publiée = wiki_pages(:blog_non_publié)
    sign_in @administrateur
  end

  test 'la page principale de la documentation est affichée' do
    get documentation_index_url

    assert_response :success
  end

  test 'la page principale de la documentation est ouverte à un utilisateur non connecté' do
    sign_out @administrateur

    get documentation_index_url

    assert_response :success
  end

  test 'la page principale n’affiche que les documentations, sans résultat de recherche' do
    get documentation_index_url

    assert_template :index
    assert_includes assigns(:wiki_pages), wiki_pages(:blog_public)
  end

  test 'la page principale affiche les documentations épinglées en premier' do
    assert_equal wiki_pages(:blog_épinglé), assigns_index_apres_visite.reorder(:created_at).first
  end

  test 'la page principale n’affiche que les neuf premières documentations' do
    10.times { |i| créer_documentation(titre: "Documentation de remplissage #{i}") }

    assert_equal 9, assigns_index_apres_visite.size
  end

  test 'une recherche mène à la page de résultats et non à la page principale' do
    get documentation_index_url(search: 'Réserver')

    assert_response :success
    assert_template :index_for_search
  end

  test 'la recherche ne retourne que les documentations correspondantes' do
    get documentation_index_url(search: 'Réserver')

    assert_includes assigns(:wiki_pages), wiki_pages(:guide_public)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:faq_publique)
  end

  test 'une recherche sans résultat mène à la page de résultats sans documentation' do
    get documentation_index_url(search: 'astrophysique')

    assert_template :index_for_search
    assert_empty assigns(:wiki_pages)
  end

  # ==================== TESTS CRITIQUES ====================
  # La documentation est le seul écran ouvert au public, et les agents n'ont
  # aucune raison d'y lire les notes internes des gestionnaires : une page
  # privée ou non publiée qui remonterait dans une liste sortirait de
  # l'organisation.

  test 'un utilisateur non connecté ne voit aucune documentation privée dans la liste (critique)' do
    sign_out @administrateur

    get documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_privée
  end

  test 'un utilisateur non connecté ne voit aucune documentation non publiée dans la liste (critique)' do
    sign_out @administrateur

    get documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'un utilisateur non connecté ne voit aucune documentation privée dans les résultats de recherche (critique)' do
    sign_out @administrateur

    get documentation_index_url(search: 'Note interne')

    assert_not_includes assigns(:wiki_pages), @documentation_privée
  end

  test 'un agent ne voit aucune documentation privée dans la liste (critique)' do
    sign_in users(:martin_technique_paris)

    get documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_privée
  end

  test 'un agent ne voit aucune documentation non publiée dans la liste (critique)' do
    sign_in users(:martin_technique_paris)

    get documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'un agent ne voit aucune documentation privée dans les résultats de recherche (critique)' do
    sign_in users(:martin_technique_paris)

    get documentation_index_url(search: 'Note interne')

    assert_not_includes assigns(:wiki_pages), @documentation_privée
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un manager voit les documentations privées et non publiées dans la liste' do
    sign_in users(:hidalgo)

    get documentation_index_url

    assert_includes assigns(:wiki_pages), @documentation_privée
    assert_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'un adhérent ne voit aucune documentation non publiée dans la liste' do
    sign_in users(:weil)

    get documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'une documentation est affichée avec son titre' do
    get documentation_url(@documentation)

    assert_response :success
    assert_dom 'h1', text: /#{@documentation.titre}/
  end

  test 'le formulaire de création est affiché' do
    get new_documentation_url

    assert_response :success
  end

  test 'une documentation est créée avec son auteur' do
    assert_difference('WikiPage.count') do
      post documentation_index_url, params: { wiki_page: paramètres_valides }
    end

    documentation_créée = WikiPage.reorder(:created_at).last
    assert_redirected_to documentation_url(documentation_créée)
    assert_equal 'Documentation créée avec succès.', flash[:notice]
    assert_equal @administrateur, documentation_créée.user
    assert_equal 'guide', documentation_créée.catégorie
  end

  test 'une documentation n’est pas créée lorsque le document joint n’est pas d’un format accepté' do
    assert_no_difference('WikiPage.count') do
      post documentation_index_url, params: { wiki_page: paramètres_valides.merge(document: document_refusé) }
    end

    assert_response :unprocessable_content
  end

  test 'le formulaire de modification est affiché' do
    get edit_documentation_url(@documentation)

    assert_response :success
  end

  test 'une documentation est modifiée' do
    patch documentation_url(@documentation), params: { wiki_page: { titre: 'Un titre entièrement neuf' } }

    assert_redirected_to documentation_url(@documentation.reload)
    assert_equal 'Documentation modifiée avec succès.', flash[:notice]
    assert_equal 'Un titre entièrement neuf', @documentation.titre
  end

  test 'une documentation n’est pas modifiée lorsque le document joint n’est pas d’un format accepté' do
    patch documentation_url(@documentation), params: { wiki_page: { titre: 'Refusé', document: document_refusé } }

    assert_response :unprocessable_content
    assert_not_equal 'Refusé', @documentation.reload.titre
  end

  test 'une documentation est mise à la corbeille lorsqu’elle est supprimée' do
    delete documentation_url(@documentation)

    assert_redirected_to documentation_index_url
    assert_equal 'Documentation supprimée avec succès.', flash[:notice]
    assert @documentation.reload.discarded?
  end

  test 'la page blog ne liste que les documentations du blog' do
    get blog_documentation_index_url

    assert_response :success
    assert_template :index_by_categorie
    assert_includes assigns(:wiki_pages), wiki_pages(:blog_public)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:guide_public)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:faq_publique)
  end

  test 'un agent ne voit aucune documentation privée sur la page blog (critique)' do
    sign_in users(:martin_technique_paris)

    get blog_documentation_index_url

    assert_not_includes assigns(:wiki_pages), @documentation_privée
    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'la page guide ne liste que les guides' do
    get guide_documentation_index_url

    assert_response :success
    assert_template :index_by_categorie
    assert_includes assigns(:wiki_pages), wiki_pages(:guide_public)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:blog_public)
  end

  test 'la page faq ne liste que les questions fréquentes' do
    get faq_documentation_index_url

    assert_response :success
    assert_template :index_by_categorie
    assert_includes assigns(:wiki_pages), wiki_pages(:faq_publique)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:blog_public)
  end

  test 'un slug de documentation inconnu redirige sans planter' do
    get documentation_url('documentation-inexistante')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end

  private

  # Le corps de la réponse entier dans un message d'échec est illisible : on ne
  # rapporte que le titre qui a fuité et l'endroit où il est lisible.
  def refute_titre_lisible(documentation)
    assert_not response.body.include?(documentation.titre),
               "le titre « #{documentation.titre} » ne doit apparaître nulle part sur la page"
    assert_dom 'a[href=?]', documentation_path(documentation), count: 0
  end

  def assigns_index_apres_visite
    get documentation_index_url
    assigns(:wiki_pages)
  end

  def paramètres_valides
    { titre: 'Comment pointer sur une intervention', sous_titre: 'Le scan du QRCode',
      catégorie: 'guide', publiée: true, private: false, poids: 8 }
  end

  def créer_documentation(titre:)
    WikiPage.create!(titre: titre, catégorie: :blog, publiée: true, private: false,
                     épinglée: false, poids: 20, user: @administrateur)
  end

  # Aucun format n'étant refusé par le navigateur seul, c'est la validation de
  # `PieceJointeValidable` qui fait échouer l'enregistrement.
  def document_refusé
    fixture_file_upload('responseMeteoConcept.json', 'application/json')
  end
end
