# frozen_string_literal: true

require 'test_helper'

class PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @clé_mistral_initiale = ENV.fetch('MISTRAL_AI_API_KEY', nil)
    ENV['MISTRAL_AI_API_KEY'] = 'clé-de-test'
  end

  teardown do
    ENV['MISTRAL_AI_API_KEY'] = @clé_mistral_initiale
  end

  test 'l’assistant n’affiche aucune proposition sans soumission' do
    sign_in users(:administrateur_paris)

    get assistant_url

    assert_response :success
    assert_nil assigns(:results)
  end

  test 'l’assistant ne sollicite pas le LLM sans clic sur le bouton de génération' do
    sign_in users(:administrateur_paris)
    llm_called = false

    Langchain::LLM::MistralAI.stub(:new, ->(*) { llm_called = true; FakeLlm.new }) do
      get assistant_url
    end

    assert_response :success
    assert_not llm_called, 'le LLM ne doit pas être sollicité sans clic sur le bouton'
    assert_nil assigns(:results)
  end

  test 'l’assistant signale le manque d’interventions sans solliciter le LLM' do
    sign_in users(:administrateur_paris)
    llm_called = false

    Langchain::LLM::MistralAI.stub(:new, ->(*) { llm_called = true; FakeLlm.new }) do
      get assistant_url, params: { commit: 'Lancer la génération de propositions' }
    end

    assert_response :success
    assert_not llm_called, 'sous le minimum, aucun appel LLM'
    assert_match(/pas encore assez/, assigns(:results))
  end

  test 'l’assistant refuse de générer en dessous du minimum d’interventions' do
    sign_in users(:administrateur_paris)

    get assistant_url(commit: 'Générer')

    assert_response :success
    assert_match(/pas encore assez d'interventions/i, assigns(:results))
  end

  test 'la proposition du LLM est affichée mise en forme' do
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

  test 'un échec du LLM est signalé sans planter' do
    sign_in users(:administrateur_paris)
    cree_interventions_planifiees(10)
    stub_request(:post, %r{api\.mistral\.ai}).to_return(status: 500, body: 'boom')

    get assistant_url(commit: 'Générer')

    assert_response :success
    assert assigns(:is_failed)
    assert_match(/Veuillez attendre/i, assigns(:results))
  end

  test 'les mentions légales sont affichées sans être connecté' do
    get mentions_legales_url

    assert_response :success
  end

  test 'la page de bienvenue est affichée avec succès' do
    get welcome_url
    assert_response :success
  end

  test 'la page de bienvenue est affichée sans être connecté' do
    get welcome_url

    assert_response :success
  end

  test 'la page de bienvenue est affichée en étant connecté' do
    sign_in users(:hidalgo)

    get welcome_url
    assert_response :success
  end

  test 'la page de bienvenue utilise son layout dédié' do
    get welcome_url

    assert_template layout: 'layouts/welcome'
  end

  test 'le tableau de bord est affiché pour un manager' do
    sign_in users(:hidalgo)

    get dashboard_url
    assert_response :success
  end

  test 'le tableau de bord est affiché pour un adhérent' do
    sign_in users(:weil)

    get dashboard_url
    assert_response :success
  end

  test 'le tableau de bord est affiché pour un manager sans intervention' do
    sign_in users(:michael_jackson)

    get dashboard_url
    assert_response :success
  end

  test 'le tableau de bord est affiché pour un adhérent sans intervention' do
    sign_in users(:emmanuel_valls)

    get dashboard_url
    assert_response :success
  end

  test 'les pages solution, tarifs et contact sont affichées sans être connecté' do
    %i[solution_url tarifs_url contact_url].each do |route|
      get send(route)

      assert_response :success, "#{route} doit être publique"
    end
  end

  test 'la page d’accueil est affichée pour un utilisateur connecté' do
    sign_in users(:hidalgo)

    get home_url

    assert_response :success
  end

  # doit être proposé nulle part.
  test 'l’action rapide « nouvel utilisateur » de la page d’accueil mène au formulaire de création d’un utilisateur' do
    sign_in users(:hidalgo)

    get home_url

    assert_select "a[href=?]", admin_create_new_user_path
  end

  test 'un agent n’a aucune action rapide de gestion sur la page d’accueil' do
    sign_in users(:bond)

    get home_url

    assert_select "a[href=?]", admin_create_new_user_path, count: 0
  end

  test 'la page d’accueil affiche avant 7h la bannière du créneau 20h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 3, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[20], assigns(:banner_background_color)
    assert_equal 'banner/banner_20h.jpg', assigns(:banner_image_name)
  end

  test 'la page d’accueil affiche à 7h la bannière du créneau plancher 8h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 7, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[8], assigns(:banner_background_color)
  end

  test 'la page d’accueil affiche à 19h la bannière du créneau plafond 18h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 19, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[18], assigns(:banner_background_color)
  end

  test 'la page d’accueil affiche à midi la bannière du créneau 12h' do
    sign_in users(:hidalgo)

    travel_to Time.new(2026, 7, 1, 12, 0, 0) do
      get home_url
    end

    assert_equal ApplicationController::BACKGROUND_COLORS[12], assigns(:banner_background_color)
  end

  # les fixtures partagent toutes le même updated_at : d'où le décalage explicite.
  test 'le bouton Terminer d’une fille de pointage mène au pointage de son modèle' do
    mère  = interventions(:intervention_repete)
    fille = interventions(:intervention_fille)
    fille.update_columns(template_slug: mère.slug, updated_at: 1.minute.from_now)
    sign_in users(:martin_technique_paris)

    get home_url

    assert_response :success
    assert_select "form[action=?][method=?]", pointer_intervention_path(mère), 'get'
    assert_select "form[action=?]", terminer_intervention_path(fille), count: 0
  end

  test 'le bouton Terminer d’une intervention hors pointage déclenche directement sa terminaison' do
    intervention = interventions(:nouvelle_intervention)
    intervention.update_columns(updated_at: 1.minute.from_now, temps_de_pause: 0)
    sign_in users(:martin_technique_paris)

    get home_url

    assert_response :success
    assert_nil intervention.template_slug
    assert_select "form[action=?][method=?]", terminer_intervention_path(intervention), 'post'
  end

  # de son action.
  test 'le bouton Terminer d’une intervention sans date de fin renvoie au formulaire de modification' do
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

  test 'la page météo est affichée avec des prévisions' do
    sign_in users(:hidalgo)

    get meteo_url

    assert_response :success
    assert assigns(:forecasts).present?
  end

  test 'la météo d’un jour valide est retournée en JSON avec sa prévision et son libellé' do
    sign_in users(:hidalgo)

    get meteo_by_day_url(day: 0)

    assert_response :success
    body = JSON.parse(response.body)
    assert body['forecast'].present?
    assert_equal 'Peu nuageux', body['weather'] # code weather 1 dans la fixture
  end

  test 'la météo d’un jour hors bornes est un JSON vide' do
    sign_in users(:hidalgo)

    get meteo_by_day_url(day: 99)

    assert_response :success
    assert_equal({}, JSON.parse(response.body))
  end

  # Fake LLM minimal : reproduit le contrat utilisé par le contrôleur
  # (chat(...).chat_completion) sans jamais toucher l'API Mistral.
  class FakeLlm
    Response = Struct.new(:chat_completion)

    def chat(*)
      Response.new('# Proposition\nContenu généré')
    end
  end

  private

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
