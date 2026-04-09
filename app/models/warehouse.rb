class Warehouse < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  acts_as_taggable_on :tags

  belongs_to :organisation

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

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
