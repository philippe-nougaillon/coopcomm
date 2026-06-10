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
    get wiki_pages_url(@wiki_page)
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
end
