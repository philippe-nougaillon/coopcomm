# frozen_string_literal: true

require 'test_helper'

class FetchRoutesInfosTest < ActiveSupport::TestCase
  DEPART  = { lat: 48.864388487354134, lng: 2.3395163956353677 }.freeze
  ARRIVEE = { lat: 48.85685812374327, lng: 2.351386343078722 }.freeze

  # Toutes les grandeurs restituées sont doublées : le trajet compté est
  # l'aller-retour de l'agent.
  ROUTE = {
    'distanceMeters' => 1662,
    'duration' => '660s',
    'travelAdvisory' => { 'fuelConsumptionMicroliters' => '185379' }
  }.freeze

  # ==========================================================================
  # A. Corps de la requête envoyée à Google
  # ==========================================================================

  test 'les coordonnées de départ et d’arrivée sont transmises telles quelles' do
    corps = FetchRoutesInfos.new(DEPART, ARRIVEE).get_body_request(DEPART, ARRIVEE)

    assert_equal DEPART[:lat], corps[:origin][:location][:latLng][:latitude]
    assert_equal DEPART[:lng], corps[:origin][:location][:latLng][:longitude]
    assert_equal ARRIVEE[:lat], corps[:destination][:location][:latLng][:latitude]
    assert_equal ARRIVEE[:lng], corps[:destination][:location][:latLng][:longitude]
  end

  test 'le trajet est demandé en voiture avec la consommation de carburant' do
    corps = FetchRoutesInfos.new(DEPART, ARRIVEE).get_body_request(DEPART, ARRIVEE)

    assert_equal 'DRIVE', corps[:travelMode]
    assert_equal 'FUEL_CONSUMPTION', corps[:extraComputations]
    assert_equal 'TRAFFIC_AWARE_OPTIMAL', corps[:routingPreference]
  end

  test 'la requête part avec la clé d’API et le masque de champs' do
    avec_variable_env('GOOGLE_MAPS_BACKEND_API_KEY', 'cle-google-de-test') do
      FetchRoutesInfos.call(DEPART, ARRIVEE)
    end

    assert_requested(:post, /routes.googleapis.com/,
                     headers: { 'X-Goog-Api-Key' => 'cle-google-de-test' })
  end

  # ==========================================================================
  # B. co2_consumption_by_route
  # ==========================================================================

  test 'aucun CO2 sans trajet' do
    assert_equal 0, FetchRoutesInfos.co2_consumption_by_route(nil)
  end

  test 'aucun CO2 pour un trajet vide' do
    assert_equal 0, FetchRoutesInfos.co2_consumption_by_route({})
  end

  test 'aucun CO2 sans donnée de consommation' do
    assert_equal 0.0, FetchRoutesInfos.co2_consumption_by_route({ 'distanceMeters' => 1662 })
  end

  test 'le CO2 vaut la consommation aller-retour à 2,31 kg par litre' do
    assert_in_delta 0.86, FetchRoutesInfos.co2_consumption_by_route(ROUTE), 0.001
  end

  test 'le CO2 est arrondi à deux décimales' do
    route = { 'travelAdvisory' => { 'fuelConsumptionMicroliters' => '1234567' } }

    assert_equal 5.7, FetchRoutesInfos.co2_consumption_by_route(route)
  end

  # ==========================================================================
  # C. get_trajet_from_response
  # ==========================================================================

  test 'le résumé de trajet réunit distance, durée, essence et CO2' do
    service = FetchRoutesInfos.new(DEPART, ARRIVEE)

    resume = service.get_trajet_from_response({ 'routes' => [ROUTE] })

    assert_equal 'Distance: 3 km, Durée: 22 min, Essence: 0.37 L, CO₂: 0.86 kg', resume
  end

  # Les durées sont doublées (aller-retour) avant d'être mises en forme :
  # 1770 s de trajet simple donnent 59 min de trajet compté.
  test 'une durée de moins d\'une heure est donnée en minutes' do
    assert_includes duree_affichee(1770), 'Durée: 59 min'
  end

  test 'une durée d\'une heure pile est donnée en heures et minutes' do
    assert_includes duree_affichee(1800), 'Durée: 1h 00min'
  end

  test 'les minutes d\'une durée en heures sont sur deux chiffres' do
    assert_includes duree_affichee(1860), 'Durée: 1h 02min'
  end

  test 'une durée de plusieurs heures est donnée en heures et minutes' do
    assert_includes duree_affichee(3630), 'Durée: 2h 01min'
  end

  test 'une durée absente est donnée à zéro minute' do
    assert_includes duree_affichee(nil), 'Durée: 0 min'
  end

  test 'un résumé de trajet est vide sans aucune route' do
    service = FetchRoutesInfos.new(DEPART, ARRIVEE)

    assert_equal '', service.get_trajet_from_response({ 'routes' => [] })
  end

  test 'un résumé de trajet est vide quand la clé des routes est absente' do
    service = FetchRoutesInfos.new(DEPART, ARRIVEE)

    assert_equal '', service.get_trajet_from_response({})
  end

  test 'une distance absente est affichée à zéro plutôt que de faire échouer le calcul' do
    service = FetchRoutesInfos.new(DEPART, ARRIVEE)
    route = ROUTE.except('distanceMeters')

    assert_includes service.get_trajet_from_response({ 'routes' => [route] }), 'Distance: 0km'
  end

  test 'seule la première route proposée est retenue' do
    service = FetchRoutesInfos.new(DEPART, ARRIVEE)
    autre = ROUTE.merge('distanceMeters' => 99_999)

    resume = service.get_trajet_from_response({ 'routes' => [ROUTE, autre] })

    assert_includes resume, 'Distance: 3 km'
  end

  # ==========================================================================
  # D. call
  # ==========================================================================

  test 'le résultat rappelle les deux localisations demandées' do
    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_equal DEPART, resultat['localisation_depart']
    assert_equal ARRIVEE, resultat['localisation_arrivee']
  end

  test 'une réponse de Google au bon format produit le résumé du trajet' do
    stub_google('routes' => [ROUTE])

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_equal 'Distance: 3 km, Durée: 22 min, Essence: 0.37 L, CO₂: 0.86 kg', resultat['routes_info']
  end

  test 'la réponse brute de Google est conservée dans le résultat' do
    stub_google('routes' => [ROUTE])

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_equal [ROUTE], resultat['data_response']['routes']
  end

  test 'une erreur renvoyée par Google est reportée avec sa destination' do
    stub_google('error' => { 'message' => 'API key not valid' })

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_equal ARRIVEE, resultat['errors'][:position]
    assert_equal 'API key not valid', resultat['errors'][:message]
  end

  test 'aucun résumé de trajet n’est calculé quand Google renvoie une erreur' do
    stub_google('error' => { 'message' => 'API key not valid' })

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_nil resultat['routes_info']
  end

  test 'aucune erreur n’est reportée quand Google répond normalement' do
    stub_google('routes' => [ROUTE])

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_nil resultat['errors']
  end

  test 'une réponse sans aucune route produit un résumé vide' do
    stub_google('routes' => [])

    resultat = FetchRoutesInfos.call(DEPART, ARRIVEE)

    assert_equal '', resultat['routes_info']
  end

  private

  def duree_affichee(secondes)
    route = ROUTE.merge('duration' => secondes.nil? ? nil : "#{secondes}s")

    FetchRoutesInfos.new(DEPART, ARRIVEE).get_trajet_from_response({ 'routes' => [route] })
  end

  def stub_google(corps)
    stub_request(:post, /routes.googleapis.com/)
      .to_return(status: 200, body: corps.to_json, headers: { 'Content-Type' => 'application/json' })
  end

  # Les workers parallèles partagent le processus : une clé laissée en place
  # contamine les tests système du même worker (script Google Maps du formulaire).
  def avec_variable_env(nom, valeur)
    ancienne = ENV[nom]
    ENV[nom] = valeur
    yield
  ensure
    ENV[nom] = ancienne
  end
end
