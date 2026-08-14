# frozen_string_literal: true

require 'test_helper'

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wiki_page = wiki_pages(:blog_only_admin)
    sign_in users(:administrateur_paris)
  end

  test 'index : sans paramètre → la page répond' do
    get wiki_pages_url

    assert_response :success
  end

  # Les fixtures ne renseignent pas `catégorie` : on la pose ici, sinon les scopes
  # d'enum ne remontent rien.
  test 'index : catégorie blog → seulement les billets' do
    wiki_pages(:blog).update!(catégorie: :blog, publiée: true)
    wiki_pages(:guide).update!(catégorie: :guide, publiée: true)

    get wiki_pages_url(catégorie: 'blog')

    assert_includes assigns(:wiki_pages), wiki_pages(:blog)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:guide)
  end

  test 'index : catégorie guide → seulement les guides' do
    wiki_pages(:blog).update!(catégorie: :blog, publiée: true)
    wiki_pages(:guide).update!(catégorie: :guide, publiée: true)

    get wiki_pages_url(catégorie: 'guide')

    assert_includes assigns(:wiki_pages), wiki_pages(:guide)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:blog)
  end

  test 'index : catégorie faq → seulement les fiches' do
    wiki_pages(:fiche).update!(catégorie: :faq, publiée: true)

    get wiki_pages_url(catégorie: 'faq')

    assert_includes assigns(:wiki_pages), wiki_pages(:fiche)
  end

  test 'index : recherche → les pages dont le titre ou le contenu correspond' do
    get wiki_pages_url(search: wiki_pages(:blog).titre)

    assert_includes assigns(:wiki_pages), wiki_pages(:blog)
  end

  test 'show : une page de son organisation → la page répond' do
    get wiki_page_url(@wiki_page)

    assert_response :success
  end

  test 'new : sans paramètre → la page répond' do
    get new_wiki_page_url

    assert_response :success
  end

  test 'edit : une page de son organisation → la page répond' do
    get edit_wiki_page_url(@wiki_page)

    assert_response :success
  end

  test 'create : paramètres valides → la page est créée' do
    assert_difference('WikiPage.count') do
      post wiki_pages_url, params: {
        wiki_page: { titre: @wiki_page.titre, publiée: @wiki_page.publiée,
                     user: @wiki_page.user, poids: @wiki_page.poids }
      }
    end

    assert_redirected_to wiki_page_url(WikiPage.last)
  end

  test 'update : paramètres valides → la page est modifiée' do
    nouveau_titre = @wiki_page.titre + SecureRandom.uuid

    patch wiki_page_url(@wiki_page), params: {
      wiki_page: { titre: nouveau_titre, publiée: @wiki_page.publiée,
                   user: @wiki_page.user, poids: @wiki_page.poids }
    }

    assert_redirected_to wiki_page_url(WikiPage.order(updated_at: :asc).last)
    assert_equal nouveau_titre, @wiki_page.reload.titre
  end

  test 'destroy : une page de son organisation → elle est archivée' do
    assert @wiki_page.reload.undiscarded?

    delete wiki_page_url(@wiki_page)

    assert_redirected_to wiki_pages_url
    assert @wiki_page.reload.discarded?
  end

  test 'set_wiki_page : un slug inconnu redirige sans planter' do
    get wiki_page_url('page-inexistante')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
