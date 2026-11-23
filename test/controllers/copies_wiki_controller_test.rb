# frozen_string_literal: true

require 'test_helper'
require_relative '../support/page_wiki_exportee'

class CopiesWikiControllerTest < ActionDispatch::IntegrationTest
  include PageWikiExportee

  setup do
    @super_admin = users(:philippe_super_admin)
    @env_initial = ENV.to_h.slice('JETON_INSTANCES', 'SUPER_ADMIN')
    ENV['JETON_INSTANCES'] = 'jeton-de-test'
    ENV['SUPER_ADMIN'] = "#{@super_admin.email},#{users(:martin_technique_paris).email}"
  end

  # En-têtes d'une instance qui détient le jeton partagé
  EN_TÊTES = { 'Authorization' => 'Bearer jeton-de-test', 'Content-Type' => 'application/json' }.freeze

  teardown do
    %w[JETON_INSTANCES SUPER_ADMIN].each { |nom| ENV[nom] = @env_initial[nom] }
  end

  test 'les auteurs proposés sont les seuls super_admin manager ou administrateur' do
    get auteurs_copies_wiki_index_url, headers: EN_TÊTES

    assert_response :success
    assert_equal [@super_admin.email], response.parsed_body.pluck('email')
  end

  test 'une page reçue est créée au nom de l’auteur choisi' do
    assert_difference('WikiPage.count') do
      post copies_wiki_index_url, params: copie(auteur: @super_admin.email), headers: EN_TÊTES
    end

    assert_response :created
    page = WikiPage.find_by!(slug: response.parsed_body['slug'])
    assert_equal @super_admin, page.user
    assert page.publiée
  end

  test 'une page reçue pour un compte qui n’est pas super_admin n’est pas créée' do
    assert_no_difference('WikiPage.count') do
      post copies_wiki_index_url, params: copie(auteur: users(:administrateur_paris).email), headers: EN_TÊTES
    end

    assert_response :unprocessable_content
  end

  test 'une page reçue refusée par ses validations renvoie le motif' do
    page_refusée = page_wiki_exportée.merge('document' => fichier_wiki_exporté('responseMeteoConcept.json', 'application/json'))

    assert_no_difference('WikiPage.count') do
      post copies_wiki_index_url, params: { page: page_refusée, auteur: @super_admin.email, publiée: true }.to_json,
                                  headers: EN_TÊTES
    end

    assert_response :unprocessable_content
    assert_match 'Document', response.parsed_body['erreur']
  end

  # ==================== TESTS CRITIQUES ====================
  # Le jeton partagé est la seule barrière entre une instance et le reste d'Internet :
  # sans lui, n'importe qui publierait sur le wiki ou lirait la liste des super_admin.

  test 'les auteurs ne sont pas donnés sans le bon jeton (critique)' do
    get auteurs_copies_wiki_index_url, headers: EN_TÊTES.merge('Authorization' => 'Bearer faux-jeton')

    assert_response :unauthorized
    assert_not_includes response.body, @super_admin.email
  end

  test 'une page reçue sans le bon jeton n’est pas créée (critique)' do
    assert_no_difference('WikiPage.count') do
      post copies_wiki_index_url, params: copie(auteur: @super_admin.email),
                                  headers: EN_TÊTES.merge('Authorization' => 'Bearer faux-jeton')
    end

    assert_response :unauthorized
  end

  test 'une instance sans jeton configuré ne reçoit aucune page (critique)' do
    ENV.delete('JETON_INSTANCES')

    assert_no_difference('WikiPage.count') do
      post copies_wiki_index_url, params: copie(auteur: @super_admin.email),
                                  headers: EN_TÊTES.merge('Authorization' => 'Bearer ')
    end

    assert_response :unauthorized
  end

  # ==================== /TESTS CRITIQUES ====================

  private

  def copie(auteur:)
    { page: page_wiki_exportée, auteur: auteur, publiée: true,
      origine: { instance: 'demo.exemple.fr', slug: 'reserver-une-benne', par: @super_admin.email } }.to_json
  end
end
