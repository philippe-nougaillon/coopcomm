class Warehouse < ApplicationRecord
  acts_as_taggable_on :tags
  validates :localisation, presence: true

  def lng_lat
    # Inverse les variables pour correspondre aux valeurs de google
    self.localisation.gsub(/(.*?), (.*)/) { "[#{$2}, #{$1}]" }
  end

  def localisation_to_lat_lng_object
    # Sépare et nettoie la chaine localisation en latitude, longitude
    lat, lng = self.localisation.split(',').map(&:strip).map(&:to_f)
    { lat: lat, lng: lng }
  end
end
