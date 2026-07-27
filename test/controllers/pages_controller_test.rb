# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  test 'doit afficher la page welcome' do
    get welcome_url
    assert_response :success
  end

  test 'doit afficher la page welcome en étant connecté' do
    sign_in users(:hidalgo)

    get welcome_url
    assert_response :success
  end

  test "doit afficher le dashboard en tant qu'administrateur" do
    sign_in users(:hidalgo)

    get dashboard_url
    assert_response :success
  end

  test "doit afficher le dashboard en tant qu'adhérent" do
    sign_in users(:weil)

    get dashboard_url
    assert_response :success
  end

  test "ne doit pas accéder au dashboard en tant qu'agent" do
    sign_in users(:martin_technique_paris)

    get dashboard_url
    assert_redirected_to root_url
  end

  test 'doit afficher le dashboard sans intervention avec un manager' do
    sign_in users(:michael_jackson)

    get dashboard_url
    assert_response :success
  end

  test 'doit afficher le dashboard sans intervention avec un adhérent' do
    sign_in users(:emmanuel_valls)

    get dashboard_url
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # Pages vitrine publiques (welcome, mentions_legales, solution, tarifs, contact)
  # ---------------------------------------------------------------------------

  test 'la page welcome est accessible sans être connecté' do
    get welcome_url

    assert_response :success
  end

  test 'welcome utilise le layout dédié welcome' do
    get welcome_url

    assert_template layout: 'layouts/welcome'
  end

  test 'welcome n_expose que les pages wiki publiées' do
    get welcome_url

    wiki_pages = assigns(:wiki_pages)
    assert wiki_pages.present?, 'welcome doit assigner @wiki_pages'
    assert wiki_pages.all?(&:publiée), 'aucune page non publiée ne doit fuiter'
    assert_includes wiki_pages, wiki_pages(:blog)
    assert_not_includes wiki_pages, wiki_pages(:guide) # publiée: false
  end

  test 'mentions_legales est accessible sans être connecté' do
    get mentions_legales_url

    assert_response :success
  end

  test 'solution, tarifs et contact sont accessibles sans être connecté' do
    %i[solution_url tarifs_url contact_url].each do |route|
      get send(route)

      assert_response :success, "#{route} doit être publique"
    end
  end

  # ---------------------------------------------------------------------------
  # home — authentification + couleur de bannière selon l'heure
  # ---------------------------------------------------------------------------

  test 'home redirige vers la connexion si anonyme' do
    get home_url

    assert_redirected_to new_user_session_url
  end

  test 'home est accessible à un utilisateur connecté' do
    sign_in users(:hidalgo)

    get home_url

    assert_response :success
  end

  test 'la nuit (heure < 7) la bannière utilise le créneau 20h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 3, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[20], assigns(:banner_background_color)
    assert_equal 'banner/banner_20h.png', assigns(:banner_image_name)
  end

  test 'à 7h la bannière retombe sur le créneau plancher 8h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 7, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[8], assigns(:banner_background_color)
  end

  test 'à 19h la bannière retombe sur le créneau plafond 18h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 19, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[18], assigns(:banner_background_color)
  end

  test 'à midi la bannière utilise le créneau 12h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 12, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[12], assigns(:banner_background_color)
  end

  # ---------------------------------------------------------------------------
  # meteo / meteo_by_day (API météo stubbée globalement par WebMock)
  # ---------------------------------------------------------------------------

  test 'meteo est accessible à un utilisateur connecté' do
    sign_in users(:hidalgo)

    get meteo_url

    assert_response :success
    assert assigns(:forecasts).present?
  end

  test 'meteo_by_day rend la prévision et le libellé météo pour un jour valide' do
    sign_in users(:hidalgo)

    get meteo_by_day_url(day: 0)

    assert_response :success
    body = JSON.parse(response.body)
    assert body['forecast'].present?
    assert_equal 'Peu nuageux', body['weather'] # code weather 1 dans la fixture
  end

  test 'meteo_by_day redirige vers la connexion si anonyme' do
    get meteo_by_day_url(day: 0)

    assert_redirected_to new_user_session_url
  end

  test 'meteo_by_day avec un jour hors bornes rend un JSON vide' do
    sign_in users(:hidalgo)

    get meteo_by_day_url(day: 99)

    assert_response :success
    assert_equal({}, JSON.parse(response.body))
  end

  # ---------------------------------------------------------------------------
  # dashboard — bords d'autorisation
  # ---------------------------------------------------------------------------

  test 'dashboard redirige vers la connexion si anonyme' do
    get dashboard_url

    assert_redirected_to new_user_session_url
  end

  # ---------------------------------------------------------------------------
  # assistant — réservé aux administrateurs
  # ---------------------------------------------------------------------------

  test 'assistant est refusé à un non-administrateur' do
    sign_in users(:hidalgo) # manager

    get assistant_url

    assert_redirected_to root_url
  end

  test 'assistant redirige vers la connexion si anonyme' do
    get assistant_url

    assert_redirected_to new_user_session_url
  end

  test 'assistant sans commit n_appelle pas le LLM' do
    sign_in users(:administrateur_paris)
    llm_called = false

    Langchain::LLM::MistralAI.stub(:new, ->(*) { llm_called = true; FakeLlm.new }) do
      get assistant_url
    end

    assert_response :success
    assert_not llm_called, 'le LLM ne doit pas être sollicité sans clic sur le bouton'
    assert_nil assigns(:results)
  end

  test 'assistant avec commit mais trop peu d_interventions affiche le message d_attente sans appeler le LLM' do
    sign_in users(:administrateur_paris)
    llm_called = false

    Langchain::LLM::MistralAI.stub(:new, ->(*) { llm_called = true; FakeLlm.new }) do
      get assistant_url, params: { commit: 'Lancer la génération de propositions' }
    end

    assert_response :success
    assert_not llm_called, 'sous le minimum, aucun appel LLM'
    assert_match(/pas encore assez/, assigns(:results))
  end

  # Fake LLM minimal : reproduit le contrat utilisé par le contrôleur
  # (chat(...).chat_completion) sans jamais toucher l'API Mistral.
  class FakeLlm
    Response = Struct.new(:chat_completion)

    def chat(*)
      Response.new('# Proposition\nContenu généré')
    end
  end
end
