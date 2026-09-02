# frozen_string_literal: true

require 'test_helper'

class MeteoConceptConnexionTest < ActiveSupport::TestCase
  # ==========================================================================
  # ============ TEST CRITIQUE : une météo en panne ne casse rien ============
  # ==========================================================================
  # La météo décore la page d'accueil et la réservation de matériel : aucune
  # défaillance de l'API tierce ne doit remonter jusqu'à l'utilisateur.

  test "une API injoignable ne lève pas d'exception" do
    stub_request(:get, /api.meteo-concept.com/).to_timeout

    assert_nil MeteoConceptConnexion.new.fetch_response
  end

  test "une réponse en erreur ne lève pas d'exception" do
    stub_request(:get, /api.meteo-concept.com/).to_return(status: 500, body: 'boom')

    assert_nil MeteoConceptConnexion.new.fetch_response
  end

  test "un corps de réponse illisible ne lève pas d'exception" do
    stub_request(:get, /api.meteo-concept.com/)
      .to_return(status: 200, body: 'pas du json', headers: { 'Content-Type' => 'application/json' })

    assert_nil MeteoConceptConnexion.new.fetch_response
  end

  test 'une réponse non autorisée ne lève pas d’exception' do
    stub_request(:get, /api.meteo-concept.com/).to_return(status: 401, body: '{}')

    assert_nil MeteoConceptConnexion.new.fetch_response
  end

  # ==========================================================================
  # A. fetch_response — chemin nominal
  # ==========================================================================

  test 'une réponse valide est renvoyée décodée' do
    forecasts = MeteoConceptConnexion.new.fetch_response

    assert_equal 14, forecasts['forecast'].size
  end

  test "la date de la réponse est conservée dans last_fetched_at" do
    date_http = Time.utc(2026, 7, 1, 12, 0, 0).httpdate
    stub_request(:get, /api.meteo-concept.com/)
      .to_return(status: 200, body: '{"forecast":[]}',
                 headers: { 'Content-Type' => 'application/json', 'Date' => date_http })

    assert_equal date_http, MeteoConceptConnexion.new.fetch_response[:last_fetched_at]
  end

  test "la clé d'API est transmise en en-tête d'autorisation" do
    avec_variable_env('METEO_API_KEY', 'cle-de-test') do
      MeteoConceptConnexion.new.fetch_response
    end

    assert_requested(:get, /api.meteo-concept.com/,
                     headers: { 'Authorization' => 'Bearer cle-de-test' })
  end

  # ==========================================================================
  # B. call — mémoïsation
  # ==========================================================================
  # Rails.cache vaut :null_store en test : sans store dédié, fetch réévalue
  # toujours son bloc et le contrat de cache ne serait pas exercé.

  test "deux appels successifs ne déclenchent qu'un seul appel à l'API" do
    avec_cache_en_memoire do
      MeteoConceptConnexion.call
      MeteoConceptConnexion.call
    end

    assert_requested(:get, /api.meteo-concept.com/, times: 1)
  end

  test "un échec de l'API n'est pas mis en cache" do
    stub_request(:get, /api.meteo-concept.com/).to_return(status: 500, body: 'boom')

    avec_cache_en_memoire do
      MeteoConceptConnexion.call
      MeteoConceptConnexion.call
    end

    assert_requested(:get, /api.meteo-concept.com/, times: 2)
  end

  test 'le résultat mémoïsé est bien la réponse de l’API' do
    avec_cache_en_memoire do
      assert_equal 14, MeteoConceptConnexion.call['forecast'].size
    end
  end

  # ==========================================================================
  # C. get_forecast_for_date
  # ==========================================================================

  test 'aucune prévision sans données de prévision' do
    assert_nil MeteoConceptConnexion.get_forecast_for_date(Date.today, nil)
  end

  test 'aucune prévision pour une date passée' do
    assert_nil MeteoConceptConnexion.get_forecast_for_date(Date.today - 1, previsions)
  end

  test 'aucune prévision au-delà de la fenêtre de quatorze jours' do
    assert_nil MeteoConceptConnexion.get_forecast_for_date(Date.today + 14, previsions)
  end

  test 'la prévision du jour est celle de la troisième période' do
    attendue = previsions[0].third

    assert_equal attendue, MeteoConceptConnexion.get_forecast_for_date(Date.today, previsions)
  end

  test 'la prévision du dernier jour de la fenêtre est accessible' do
    attendue = previsions[13].third

    assert_equal attendue, MeteoConceptConnexion.get_forecast_for_date(Date.today + 13, previsions)
  end

  test 'la prévision correspond bien au décalage de jours demandé' do
    attendue = previsions[5].third

    assert_equal attendue, MeteoConceptConnexion.get_forecast_for_date(Date.today + 5, previsions)
  end

  # ==========================================================================
  # D. get_icon_meteo_by_date / get_title
  # ==========================================================================

  test 'aucune icône hors de la fenêtre de prévision' do
    assert_nil MeteoConceptConnexion.get_icon_meteo_by_date(Date.today + 20, previsions)
  end

  test "aucune icône sans données de prévision" do
    assert_nil MeteoConceptConnexion.get_icon_meteo_by_date(Date.today, nil)
  end

  test "l'icône du jour découle du code météo de la prévision" do
    code = previsions[0].third['weather']

    assert_equal MeteoConceptConnexion.get_icon_meteo(code),
                 MeteoConceptConnexion.get_icon_meteo_by_date(Date.today, previsions)
  end

  test "l'infobulle hors de la fenêtre de prévision ne fait pas planter la page" do
    assert_nil MeteoConceptConnexion.get_title(Date.today + 20, previsions)
  end

  test 'une réponse tronquée de l’API ne fait pas planter la recherche de prévision' do
    assert_nil MeteoConceptConnexion.get_forecast_for_date(Date.today + 5, previsions.first(3))
  end

  test "l'infobulle réunit le libellé, la température, la pluie et le vent" do
    prevision = previsions[0].third

    titre = MeteoConceptConnexion.get_title(Date.today, previsions)

    assert_includes titre, MeteoConceptConnexion.WEATHER[prevision['weather']]
    assert_includes titre, "Température : #{prevision['temp2m']} °C"
    assert_includes titre, "Probabilité de pluie : #{prevision['probarain']}%"
    assert_includes titre, "Vent : #{prevision['wind10m']} km/h"
  end

  # ==========================================================================
  # E. get_icon_meteo — correspondance code → icône
  # ==========================================================================

  test 'un code météo connu donne son icône' do
    assert_equal 'meteo/animated/day.svg', MeteoConceptConnexion.get_icon_meteo(0)
  end

  test 'un code météo hors de la table retombe sur l’icône du jour' do
    assert_equal 'meteo/animated/day.svg', MeteoConceptConnexion.get_icon_meteo(9999)
  end

  # ==========================================================================
  # F. Table des libellés
  # ==========================================================================

  test 'un code connu a son libellé' do
    assert_equal 'Soleil', MeteoConceptConnexion.WEATHER[0]
  end

  test "un code inconnu n'a pas de libellé" do
    assert_nil MeteoConceptConnexion.WEATHER[9999]
  end

  private

  def previsions
    @previsions ||= JSON.parse(File.read('test/fixtures/files/responseMeteoConcept.json'))['forecast']
  end

  def avec_cache_en_memoire
    ancien = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = ancien
  end

  # Les workers parallèles partagent le processus : une variable laissée en
  # place contamine les tests système du même worker.
  def avec_variable_env(nom, valeur)
    ancienne = ENV[nom]
    ENV[nom] = valeur
    yield
  ensure
    ENV[nom] = ancienne
  end
end
