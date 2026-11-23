# frozen_string_literal: true

require 'digest'

# L'instance OVH qui porte le modèle de langage : son état, son réveil et sa mise en pause, par l'API OVH (réglée par OVH_*).
class InstanceIa
  class Erreur < StandardError; end
  class SansReponse < Erreur; end

  API = 'https://eu.api.ovh.com/v1'
  VARIABLES = %w[OVH_APP_KEY OVH_APP_SECRET OVH_CONSUMER_KEY OVH_PROJECT_ID OVH_INSTANCE_ID].freeze
  EN_PAUSE = %w[SHELVED SHELVED_OFFLOADED].freeze
  DELAI = 5
  DELAI_D_ACTION = 30
  CACHE = 'etat_instance_ia'
  REVEIL = %w[UNSHELVING].freeze
  MISE_EN_PAUSE = %w[SHELVING].freeze

  def self.pilotable?
    VARIABLES.all? { |variable| ENV[variable].present? }
  end

  def self.etat
    requete(:get)['status']
  end

  # L'état montré sur la page d'analyse, relu chez OVH au plus toutes les trente secondes ; rien si l'instance ne se pilote
  # pas ou qu'OVH ne répond pas.
  def self.etat_affiche
    Rails.cache.fetch(CACHE, expires_in: 30.seconds) { etat } if pilotable?
  rescue Erreur
    nil
  end

  def self.reveiller
    requete(:post, '/unshelve', DELAI_D_ACTION)
  end

  def self.mettre_en_pause
    requete(:post, '/shelve', DELAI_D_ACTION)
  end

  def self.requete(methode, action = '', delai = DELAI)
    url = "#{API}/cloud/project/#{ENV.fetch('OVH_PROJECT_ID')}/instance/#{ENV.fetch('OVH_INSTANCE_ID')}#{action}"
    horodatage = Time.now.to_i.to_s
    signature = [ENV.fetch('OVH_APP_SECRET'), ENV.fetch('OVH_CONSUMER_KEY'), methode.to_s.upcase, url, '', horodatage].join('+')
    reponse = Faraday.new(request: { open_timeout: DELAI, timeout: delai }) { |connexion| connexion.response :json }
                     .run_request(methode, url, nil, 'X-Ovh-Application' => ENV.fetch('OVH_APP_KEY'), 'X-Ovh-Consumer' => ENV.fetch('OVH_CONSUMER_KEY'),
                                                     'X-Ovh-Timestamp' => horodatage, 'X-Ovh-Signature' => "$1$#{Digest::SHA1.hexdigest(signature)}")
    raise Erreur, "l'API OVH répond #{reponse.status}" unless reponse.success?

    reponse.body
  rescue Faraday::Error => e
    raise SansReponse, e.message
  end
  private_class_method :requete
end
