class Service < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation

  has_many :user_services, dependent: :destroy
  has_many :users, through: :user_services
  has_many :interventions
  has_many :conventions, dependent: :destroy
  has_many :managers, -> { manager }, through: :user_services, source: :user

  validates_uniqueness_of :nom, scope: :organisation_id

  normalizes :nom, with: -> nom { nom.humanize.strip }

  scope :ordered, -> { order(:nom) }

  def managers_and_admin
    users.where(rôle: [:manager, :administrateur])
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
