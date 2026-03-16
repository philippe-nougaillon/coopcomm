class Service < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :organisation

  has_many :user_services, dependent: :destroy
  has_many :users, through: :user_services

  validates_uniqueness_of :nom

  normalizes :nom, with: -> nom { nom.humanize.strip }

  def managers_and_admin
    users.where(rôle: [:manager, :administrateur])
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
