# frozen_string_literal: true

require 'test_helper'

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @administrateur = users(:administrateur_paris)
    @documentation = wiki_pages(:blog_de_l_administrateur)
    @documentation_privée = wiki_pages(:blog_privé)
    @documentation_non_publiée = wiki_pages(:blog_non_publié)
    @super_admin = users(:philippe_super_admin)
    @env_initial = ENV.to_h.slice('INSTANCES_COOPCOMM', 'JETON_INSTANCES', 'HOST_URL', 'SUPER_ADMIN')
    ENV['INSTANCES_COOPCOMM'] = 'Autre instance=https://autre-instance.exemple.fr,Instance courante=https://demo.exemple.fr'
    ENV['JETON_INSTANCES'] = 'jeton-de-test'
    ENV['HOST_URL'] = 'demo.exemple.fr'
    ENV['SUPER_ADMIN'] = @super_admin.email
    sign_in @administrateur
  end

  teardown do
    %w[INSTANCES_COOPCOMM JETON_INSTANCES HOST_URL SUPER_ADMIN].each { |nom| ENV[nom] = @env_initial[nom] }
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
    get documentation_index_url
    assert_equal wiki_pages(:blog_épinglé), assigns(:wiki_pages).first
  end

  test 'la page principale classe les documentations non épinglées par poids croissant' do
    get documentation_index_url

    poids = assigns(:wiki_pages).where(épinglée: false).pluck(:poids)

    assert_equal poids.sort, poids
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

  test 'la page de résultats affiche toutes les documentations trouvées d’une même catégorie' do
    documentations = Array.new(4) { |i| créer_documentation(titre: "Documentation de remplissage #{i}") }

    get documentation_index_url(search: 'remplissage')

    assert_response :success
    documentations.each do |documentation|
      assert_dom 'a.card[href=?]', documentation_path(documentation) do
        assert_dom 'h3', text: documentation.titre
      end
    end
  end

  test 'la page principale affiche une documentation avec photo et sans sous-titre' do
    documentation = créer_documentation(titre: 'Documentation illustrée sans sous-titre')
    documentation.update!(épinglée: true, photo: fixture_file_upload('exemple.png', 'image/png'))

    get documentation_index_url

    assert_response :success
    assert_dom 'a.card[href=?]', documentation_path(documentation)
  end

  # ==================== TESTS CRITIQUES ====================
  # Chaque page de la documentation doit passer par `by_role_for` : la matrice
  # rôle par rôle est éprouvée dans `wiki_page_test`, ce qui reste ici, c'est
  # qu'aucune page n'oublie de l'appeler. La documentation étant le seul écran
  # ouvert sans authentification, une page qui l'oublierait sortirait de
  # l'organisation.

  test 'la page principale ne liste que les documentations visibles par le rôle (critique)' do
    sign_in users(:martin_technique_paris)

    get documentation_index_url

    assert_includes assigns(:wiki_pages), wiki_pages(:blog_public)
    assert_not_includes assigns(:wiki_pages), @documentation_privée
    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'la page de résultats ne liste que les documentations visibles par le rôle (critique)' do
    sign_in users(:martin_technique_paris)

    get documentation_index_url(search: 'documentation')

    assert_not_includes assigns(:wiki_pages), @documentation_privée
    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'la page d’une catégorie ne liste que les documentations visibles par le rôle (critique)' do
    sign_in users(:martin_technique_paris)

    get blog_documentation_index_url

    assert_includes assigns(:wiki_pages), wiki_pages(:blog_public)
    assert_not_includes assigns(:wiki_pages), @documentation_privée
    assert_not_includes assigns(:wiki_pages), @documentation_non_publiée
  end

  test 'la barre latérale ne nomme aucune documentation invisible par le rôle (critique)' do
    sign_out @administrateur

    get documentation_index_url

    refute_titre @documentation_privée
    refute_titre @documentation_non_publiée
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une documentation est affichée avec son titre' do
    get documentation_url(@documentation)

    assert_response :success
    assert_dom 'h1', text: /#{@documentation.titre}/
  end

  test 'le formulaire de création est affiché' do
    get new_documentation_url

    assert_response :success
  end

  test 'le formulaire de création ne présélectionne aucune catégorie' do
    get new_documentation_url

    assert_nil assigns(:wiki_page).catégorie
  end

  test 'le formulaire de création ouvert depuis une catégorie la présélectionne' do
    get new_documentation_url(catégorie: 'guide')

    assert_equal 'guide', assigns(:wiki_page).catégorie
  end

  test 'le formulaire de création ne présélectionne rien lorsque la catégorie demandée n’existe pas' do
    get new_documentation_url(catégorie: 'astrologie')

    assert_response :success
    assert_nil assigns(:wiki_page).catégorie
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

  test 'le formulaire de copie propose les instances configurées, sans l’instance courante' do
    sign_in @super_admin

    get copie_documentation_url(@documentation)

    assert_response :success
    assert_equal [{ nom: 'Autre instance', url: 'https://autre-instance.exemple.fr' }], assigns(:instances)
  end

  test 'le formulaire de copie propose les auteurs de l’instance choisie' do
    sign_in @super_admin

    get copie_documentation_url(@documentation, instance: 'Autre instance')

    assert_response :success
    assert_equal ['camille.martin@autre-instance.exemple.fr'], assigns(:auteurs).pluck('email')
  end

  test 'le formulaire de copie reste affiché avec une alerte quand l’instance ne répond pas (critique)' do
    stub_request(:get, 'https://autre-instance.exemple.fr/copies_wiki/auteurs').to_timeout
    sign_in @super_admin

    get copie_documentation_url(@documentation, instance: 'Autre instance')

    assert_response :success
    assert_match 'autre-instance.exemple.fr ne répond pas', flash[:alert]
  end

  test 'une page copiée mène à sa copie sur l’autre instance' do
    sign_in @super_admin

    post copier_documentation_url(@documentation),
         params: { instance: 'Autre instance', auteur: 'camille.martin@autre-instance.exemple.fr', publiée: '1' }

    assert_redirected_to 'https://autre-instance.exemple.fr/documentation/reserver-un-outil-copie'
    assert_requested(:post, 'https://autre-instance.exemple.fr/copies_wiki') do |requête|
      corps = JSON.parse(requête.body)
      corps['page']['titre'] == @documentation.titre && corps['auteur'] == 'camille.martin@autre-instance.exemple.fr' &&
        corps['publiée'] == true &&
        corps['origine'] == { 'instance' => 'demo.exemple.fr', 'slug' => @documentation.slug, 'par' => @super_admin.email }
    end
  end

  test 'une copie refusée par l’autre instance ramène au formulaire avec son motif' do
    stub_request(:post, 'https://autre-instance.exemple.fr/copies_wiki')
      .to_return(status: 422, body: { erreur: 'auteur inconnu' }.to_json)
    sign_in @super_admin

    post copier_documentation_url(@documentation), params: { instance: 'Autre instance', auteur: 'inconnu@exemple.fr' }

    assert_redirected_to copie_documentation_path(@documentation, instance: 'Autre instance')
    assert_equal 'autre-instance.exemple.fr a refusé la demande : auteur inconnu', flash[:alert]
  end

  test 'une instance absente de la configuration ne reçoit ni la page ni le jeton (critique)' do
    stub_request(:post, 'https://pirate.exemple.fr/copies_wiki')
    sign_in @super_admin

    post copier_documentation_url(@documentation), params: { instance: 'https://pirate.exemple.fr', auteur: 'x@exemple.fr' }

    assert_redirected_to copie_documentation_path(@documentation)
    assert_equal 'Instance inconnue.', flash[:alert]
    assert_not_requested :post, 'https://pirate.exemple.fr/copies_wiki'
    assert_not_requested :post, 'https://autre-instance.exemple.fr/copies_wiki'
  end

  test 'un slug de documentation inconnu redirige sans planter' do
    get documentation_url('documentation-inexistante')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end

  private

  # Le corps de la réponse entier dans un message d'échec est illisible : on ne
  # rapporte que le titre qui a fuité et l'endroit où il est lisible.
  def refute_titre(documentation)
    assert_not response.body.include?(documentation.titre),
               "le titre « #{documentation.titre} » ne doit apparaître nulle part sur la page"
    assert_dom 'a[href=?]', documentation_path(documentation), count: 0
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
