class ApiGoogleMaps < ApplicationService

  attr_reader :map_center, :errors, :routes_info, :data_response

  def initialize(localisation_destination)
    @localisation_destination = localisation_destination
    prepare_request
  end
  
  def call
    # Prendre la route du siège de la communauté de commune vers l'adhérent courant
    #TODO : mettre en variable d'environnement, ou ailleurs
    localisation_siege = { lat: 48.953765163335845, lng: 5.865465939891961 }
    @map_center = localisation_siege

    self.prepare_body_request(localisation_siege, @localisation_destination)
    @data_response = self.get_response

    if data_response["error"]
        @errors = { position: @localisation_destination, message: data_response["error"]["message"] }
    else
        @routes_info = self.get_trajet_from_response
        @response = data_response
    end
  end
  
  def prepare_request
    url = URI("https://routes.googleapis.com/directions/v2:computeRoutes")
    @http = Net::HTTP.new(url.host, url.port)
    @http.use_ssl = true

    @request = Net::HTTP::Post.new(url)

    @request["accept"] = 'application/json'
    @request["content-type"] = 'application/json'
    @request["X-Goog-Api-Key"] = "#{ENV['GOOGLE_MAPS_API_KEY']}"
    @request["X-Goog-FieldMask"] = "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.travelAdvisory.fuelConsumptionMicroliters"
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
      travelMode: "DRIVE",
      extraComputations: "FUEL_CONSUMPTION",
      routingPreference: "TRAFFIC_AWARE_OPTIMAL",
      #requestedReferenceRoutes: ["FUEL_EFFICIENT"]
    }
  end

  def get_trajet_from_response
    route = @response["routes"].first

    distance = ((route["distanceMeters"] * 2).to_f / 1000).to_i
    duree = ((route["duration"]).to_f * 2 / 60).to_i
    essence = ((route["travelAdvisory"]["fuelConsumptionMicroliters"]).to_f * 2 / 1000000).round(2)
    co2 = self.co2_consumption_by_route(route)

    "Distance: #{distance} km, Durée: #{duree} min, Essence: #{essence} L, CO₂: #{co2} kg"
  end

  def co2_consumption_by_route(route)
    # 💡 Consommation de carburant
    fuel_microliters = route.dig("travelAdvisory", "fuelConsumptionMicroliters")
    fuel_liters = fuel_microliters.to_f / 1_000_000 if fuel_microliters

    # 💨 Conversion en CO₂ (essence : 2.31 kg CO₂ / litre)
    co2_kg = fuel_liters ? (fuel_liters * 2.31) : 0.0

    (co2_kg * 2).round(2)
  end
end