# frozen_string_literal: true

require 'test_helper'

class WikiPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wiki_page = wiki_pages(:blog_only_admin)
    sign_in users(:administrateur_paris)
  end

  test 'should get index' do
    get wiki_pages_url
    assert_response :success
  end

  test 'should show wiki page' do
    get wiki_page_url(@wiki_page)
    assert_response :success
  end

  test 'should get new' do
    get new_wiki_page_url
    assert_response :success
  end

  test 'should get edit' do
    get edit_wiki_page_url(@wiki_page)
    assert_response :success
  end

  test 'should create wiki page' do
    assert_difference('WikiPage.count') do
      post wiki_pages_url, params: {
        wiki_page: {
          titre: @wiki_page.titre,
          publiée: @wiki_page.publiée,
          user: @wiki_page.user,
          poids: @wiki_page.poids
        }
      }
    end

    assert_redirected_to wiki_page_url(WikiPage.last)
  end

  test 'should update wiki page' do
    patch wiki_page_url(@wiki_page), params: {
      wiki_page: {
        titre: @wiki_page.titre + SecureRandom.uuid,
        publiée: @wiki_page.publiée,
        user: @wiki_page.user,
        poids: @wiki_page.poids
      }
    }

    assert_redirected_to wiki_page_url(WikiPage.order(updated_at: :asc).last) # Le last ne récupère pas le dernier créé avec le scope
  end

  test 'should destroy wiki page' do
    assert @wiki_page.reload.undiscarded?

    delete wiki_page_url(@wiki_page)

    assert_redirected_to wiki_pages_url

    assert @wiki_page.reload.discarded?
  end

  # --- index : catégories et recherche ---

  # Les fixtures ne renseignent pas `catégorie` : on la pose ici, sinon les scopes
  # d'enum ne remontent rien.
  test 'index sur la catégorie blog ne liste que les billets' do
    wiki_pages(:blog).update!(catégorie: :blog, publiée: true)
    wiki_pages(:guide).update!(catégorie: :guide, publiée: true)

    get wiki_pages_url(catégorie: 'blog')

    assert_response :success
    assert_includes assigns(:wiki_pages), wiki_pages(:blog)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:guide)
  end

  test 'index sur la catégorie guide ne liste que les guides' do
    wiki_pages(:blog).update!(catégorie: :blog, publiée: true)
    wiki_pages(:guide).update!(catégorie: :guide, publiée: true)

    get wiki_pages_url(catégorie: 'guide')

    assert_response :success
    assert_includes assigns(:wiki_pages), wiki_pages(:guide)
    assert_not_includes assigns(:wiki_pages), wiki_pages(:blog)
  end

  test 'index sur la catégorie faq ne liste que les fiches' do
    wiki_pages(:fiche).update!(catégorie: :faq, publiée: true)

    get wiki_pages_url(catégorie: 'faq')

    assert_response :success
    assert_includes assigns(:wiki_pages), wiki_pages(:fiche)
  end

  test 'index avec une recherche interroge titre et contenu' do
    get wiki_pages_url(search: wiki_pages(:blog).titre)

    assert_response :success
    assert_includes assigns(:wiki_pages), wiki_pages(:blog)
  end

  # ÉPINGLAGE BUG — les vues jbuilder générées interrogent `nom`, attribut absent
  # de WikiPage : toute requête JSON sur la ressource lève. À inverser à la
  # correction des vues.
  test 'la réponse JSON d\'une page wiki lève sur un attribut inexistant' do
    assert_raises(ActionView::Template::Error) do
      get wiki_page_url(@wiki_page, format: :json)
    end
  end

  test 'un slug de page wiki inconnu redirige au lieu de planter' do
    get wiki_page_url('page-inexistante')

    assert_redirected_to root_path
    assert_match(/introuvable/i, flash[:alert].to_s)
  end
end
