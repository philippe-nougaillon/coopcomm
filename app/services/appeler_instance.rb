# frozen_string_literal: true

class AppelerInstance < ApplicationService
  class Erreur < StandardError; end

  def initialize(url, chemin, corps = nil)
    @uri = URI.join(url, chemin)
    @corps = corps
  end

  def call
    réponse = Net::HTTP.start(@uri.host, @uri.port, use_ssl: @uri.scheme == 'https', open_timeout: 10, read_timeout: 300) do |http|
      http.request(requête)
    end
    données = JSON.parse(réponse.body)
    return données if réponse.is_a?(Net::HTTPSuccess)

    raise Erreur, "#{@uri.host} a refusé la demande : #{données['erreur']}"
  rescue JSON::ParserError
    raise Erreur, "#{@uri.host} a rendu une réponse illisible (#{réponse&.code})"
  rescue SystemCallError, SocketError, IOError, Timeout::Error, OpenSSL::SSL::SSLError => e
    raise Erreur, "#{@uri.host} ne répond pas (#{e.message})"
  end

  private

  def requête
    requête = @corps ? Net::HTTP::Post.new(@uri) : Net::HTTP::Get.new(@uri)
    requête['Authorization'] = "Bearer #{ENV['JETON_INSTANCES']}"
    requête['Content-Type'] = 'application/json'
    requête.body = @corps.to_json if @corps
    requête
  end
end
