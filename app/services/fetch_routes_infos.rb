# frozen_string_literal: true

class FetchRoutesInfos < ApplicationService

  # L'initialisation prend désormais le départ et l'arrivée
  def initialize(localisation_depart, localisation_arrivee)
    @localisation_depart = localisation_depart
    @localisation_arrivee = localisation_arrivee
    prepare_request
  end

  def call
    prepare_body_request(@localisation_depart, @localisation_arrivee)

    response = {}
    response["data_response"] = get_response

    if response["data_response"]['error']
      # Pas utilisé
      response["errors"] = { position: @localisation_arrivee, message: response["data_response"]['error']['message'] }
    else
      response["routes_info"] = get_trajet_from_response(response["data_response"])
    end

    response["localisation_depart"] = @localisation_depart
    response["localisation_arrivee"] = @localisation_arrivee

    return response
  end

  def prepare_request
    url = URI('https://routes.googleapis.com/directions/v2:computeRoutes')
    @http = Net::HTTP.new(url.host, url.port)
    @http.use_ssl = true

    @request = Net::HTTP::Post.new(url)

    @request['accept'] = 'application/json'
    @request['content-type'] = 'application/json'
    @request['X-Goog-Api-Key'] = ENV['GOOGLE_MAPS_BACKEND_API_KEY'].to_s
    @request['X-Goog-FieldMask'] =
      'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.travelAdvisory.fuelConsumptionMicroliters'
  end

  def get_response
    @response = JSON.parse(@http.request(@request).read_body)
  end

  def prepare_body_request(origin, destination)
    @request.body = get_body_request(origin, destination).to_json

    self
  end

  def get_body_request(origin, destination)
    {
      origin: {
        location: {
          latLng: {
            latitude: origin[:lat],
            longitude: origin[:lng]
          }
        }
      },
      destination: {
        location: {
          latLng: {
            latitude: destination[:lat],
            longitude: destination[:lng]
          }
        }
      },
      travelMode: 'DRIVE',
      extraComputations: 'FUEL_CONSUMPTION',
      routingPreference: 'TRAFFIC_AWARE_OPTIMAL'
      # requestedReferenceRoutes: ["FUEL_EFFICIENT"]
    }
  end

  def get_trajet_from_response(data_response)
    if data_response['routes'].present?
      route = data_response['routes'].first

      # Pour éviter que ça plante, lorsque le point de départ est le même que le point d'arrivé
      msg_distance = if route['distanceMeters']
                       "Distance: #{((route['distanceMeters'] * 2).to_f / 1000).to_i} km"
                     else
                       'Distance: 0km'
                     end

      duree = (route['duration'].to_f * 2 / 60).to_i
      essence = (route['travelAdvisory']['fuelConsumptionMicroliters'].to_f * 2 / 1_000_000).round(2)
      co2 = FetchRoutesInfos.co2_consumption_by_route(route)

      "#{msg_distance}, Durée: #{duree} min, Essence: #{essence} L, CO₂: #{co2} kg"
    else
      ''
    end
  end

  def self.co2_consumption_by_route(route)
    return 0 if route.blank?
    
    # 💡 Consommation de carburant
    fuel_microliters = route.dig('travelAdvisory', 'fuelConsumptionMicroliters')
    fuel_liters = fuel_microliters.to_f / 1_000_000 if fuel_microliters

    # 💨 Conversion en CO₂ (essence : 2.31 kg CO₂ / litre)
    co2_kg = fuel_liters ? (fuel_liters * 2.31) : 0.0

    (co2_kg * 2).round(2)
  end
end
