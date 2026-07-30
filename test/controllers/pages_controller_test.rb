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
  # home — authentification + couleur de bannière selon l'heure.

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

  # La home n'affiche que les 2 interventions les plus récemment mises à jour, or
  # les fixtures partagent toutes le même updated_at : d'où le décalage explicite.
  test 'home : le bouton Terminer d\'un agent pointe vers `pointer` de l\'intervention modèle' do
    mère  = interventions(:intervention_repete)
    fille = interventions(:intervention_fille)
    fille.update_columns(template_slug: mère.slug, updated_at: 1.minute.from_now)
    sign_in users(:martin_technique_paris)

    get home_url

    assert_response :success
    assert_select "form[action=?][method=?]", pointer_intervention_path(mère), 'get'
    assert_select "form[action=?]", terminer_intervention_path(fille), count: 0
  end

  test 'home : le bouton Terminer d\'une intervention hors pointage poste vers `terminer`' do
    intervention = interventions(:nouvelle_intervention)
    intervention.update_columns(updated_at: 1.minute.from_now)
    sign_in users(:martin_technique_paris)

    get home_url

    assert_response :success
    assert_nil intervention.template_slug
    assert_select "form[action=?][method=?]", terminer_intervention_path(intervention), 'post'
  end

  # Le paramètre voyage en champ caché : un formulaire GET perd la query string
  # de son action.
  test 'home : sans date de fin, le bouton Terminer renvoie au formulaire' do
    intervention = interventions(:nouvelle_intervention)
    intervention.update_columns(fin: nil, updated_at: 1.minute.from_now)
    sign_in users(:martin_technique_paris)

    get home_url

    assert_response :success
    assert_select "form[action=?][method=?]", edit_intervention_path(intervention), 'get' do
      assert_select "input[type=hidden][name=terminer][value=?]", '1'
    end
    assert_select "form[action=?]", terminer_intervention_path(intervention), count: 0
  end

  # ---------------------------------------------------------------------------
  # meteo / meteo_by_day (API météo stubbée globalement par WebMock)

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
  # dashboard — bords d'autorisation.

  test 'dashboard redirige vers la connexion si anonyme' do
    get dashboard_url

    assert_redirected_to new_user_session_url
  end

  # ---------------------------------------------------------------------------
  # assistant — réservé aux administrateurs.

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

  # --- assistant : génération de tâches par le LLM ---

  test 'assistant sans soumission ne génère rien' do
    sign_in users(:administrateur_paris)

    get assistant_url

    assert_response :success
    assert_nil assigns(:results)
  end

  test 'assistant refuse de générer en dessous du minimum d\'interventions' do
    sign_in users(:administrateur_paris)

    get assistant_url(commit: 'Générer')

    assert_response :success
    assert_match(/pas encore assez d'interventions/i, assigns(:results))
  end

  test 'assistant met en forme la proposition du LLM' do
    skip 'Mistral API key not available in CI' if ENV['CI'].present?

    sign_in users(:administrateur_paris)
    cree_interventions_planifiees(10)
    stub_request(:post, %r{api\.mistral\.ai})
      .to_return(status: 200,
                 headers: { 'Content-Type' => 'application/json' },
                 body: {
                   id: 'cmpl-test', object: 'chat.completion', created: 1, model: 'mistral-large-latest',
                   choices: [{ index: 0, message: { role: 'assistant', content: '**Tailler les haies**' },
                               finish_reason: 'stop' }],
                   usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 }
                 }.to_json)

    get assistant_url(commit: 'Générer')

    assert_response :success
    assert_match(/Tailler les haies/, assigns(:results))
    assert_match(%r{<strong>}, assigns(:results))
    assert_nil assigns(:is_failed)
  end

  test 'assistant signale un échec du LLM sans planter' do
    sign_in users(:administrateur_paris)
    cree_interventions_planifiees(10)
    stub_request(:post, %r{api\.mistral\.ai}).to_return(status: 500, body: 'boom')

    get assistant_url(commit: 'Générer')

    assert_response :success
    assert assigns(:is_failed)
    assert_match(/Veuillez attendre/i, assigns(:results))
  end

  # Le seuil de l'assistant est de 10 interventions planifiées (hors pointages).
  def cree_interventions_planifiees(nombre)
    nombre.times do |i|
      jour = Date.new(2024, 2, 1) + i
      Intervention.create!(
        description: "Intervention planifiée #{i}",
        adherent: users(:weil),
        service: services(:technique),
        workflow_state: 'nouveau',
        début_prévue: jour + 8.hours,
        fin_prévue: jour + 10.hours,
        slug: SecureRandom.uuid
      )
    end
  end
end
