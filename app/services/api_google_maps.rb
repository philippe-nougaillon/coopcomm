class ApiGoogleMaps < ApplicationService
  attr_reader :localisation_depart, :localisation_destination, :errors, :routes_info, :data_response

  # L'initialisation prend désormais le départ et la destination
  def initialize(localisation_depart, localisation_destination)
    @localisation_depart = localisation_depart
    @localisation_destination = localisation_destination
    prepare_request
  end
  
  def call
    self.prepare_body_request(@localisation_depart, @localisation_destination)
    @data_response = self.get_response

    if @data_response["error"]
        @errors = { position: @localisation_destination, message: @data_response["error"]["message"] }
    else
        @routes_info = self.get_trajet_from_response
        @response = @data_response
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
    if @response["routes"].present?
      route = @response["routes"].first

      # Pour éviter que ça plante, lorsque le point de départ est le même que le point d'arrivé
      if route["distanceMeters"]
        msg_distance = "Distance: #{((route["distanceMeters"] * 2).to_f / 1000).to_i} km"
      else
        msg_distance = "Distance: 0km"
      end

      duree = ((route["duration"]).to_f * 2 / 60).to_i
      essence = ((route["travelAdvisory"]["fuelConsumptionMicroliters"]).to_f * 2 / 1000000).round(2)
      co2 = self.co2_consumption_by_route(route)

      "#{msg_distance}, Durée: #{duree} min, Essence: #{essence} L, CO₂: #{co2} kg"
    else
      ""
    end
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