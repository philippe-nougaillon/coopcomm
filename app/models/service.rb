# frozen_string_literal: true

class Service < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation

  has_many :user_services, dependent: :destroy
  has_many :users, through: :user_services
  has_many :interventions
  has_many :conventions, dependent: :destroy
  has_many :cotations, dependent: :destroy
  has_many :commandes, dependent: :destroy
  has_many :factures, dependent: :destroy
  has_many :managers, -> { manager }, through: :user_services, source: :user

  validates :nom, presence: true
  validates_uniqueness_of :nom, scope: :organisation_id

  normalizes :nom, with: ->(nom) { nom.humanize.strip }

  scope :ordered, -> { order(Arel.sql('LOWER(services.nom) ASC')) }

  def managers_and_admin
    users.where(rôle: %i[manager administrateur])
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
