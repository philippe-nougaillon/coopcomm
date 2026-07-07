# frozen_string_literal: true

class Warehouse < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :users, dependent: :nullify

  validates :address, :latitude, :longitude, presence: true

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
