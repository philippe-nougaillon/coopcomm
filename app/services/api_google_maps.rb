class ApiGoogleMaps < ApplicationService
  def initialize
    prepare_request
  end
  
  def prepare_request
    url = URI("https://routes.googleapis.com/directions/v2:computeRoutes")
    @http = Net::HTTP.new(url.host, url.port)
    @http.use_ssl = true

    @request = Net::HTTP::Post.new(url)

    @request["accept"] = 'application/json'
    @request["content-type"] = 'application/json'
    @request["X-Goog-Api-Key"] = "#{ENV['GOOGLE_MAPS_API_KEY']}"
    @request["X-Goog-FieldMask"] = "routes.duration,routes.distanceMeters"
  end

  def get_response
      response = JSON.parse(@http.request(@request).read_body)
      
      puts "Lancement de la requête terminée : "
      puts response

      response
  end

  def prepare_body_request(body)
      @request.body = body.to_json

      self
  end
end