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

  scope :ordered, -> { trié_par(:nom) }

  triable_par 'services.nom' => :texte,
              'services.users' => "(SELECT STRING_AGG(#{TriTextuel.expression('users.nom')}, ',' " \
                                  "ORDER BY #{TriTextuel.expression('users.nom')}) FROM users " \
                                  'INNER JOIN user_services ON user_services.user_id = users.id ' \
                                  'WHERE user_services.service_id = services.id AND users.discarded_at IS NULL)',
              'services.users_count' => '(SELECT COUNT(*) FROM user_services ' \
                                        'INNER JOIN users ON users.id = user_services.user_id ' \
                                        'WHERE user_services.service_id = services.id ' \
                                        'AND users.discarded_at IS NULL)',
              'services.calculate_distance' => :brut

  def managers_and_admin
    users.where(rôle: %i[manager administrateur])
  end

  # Vérifie que le service n'a pas de relations avec des 
  # interventions, conventions, cotations, commandes, factures ni d'utillisateurs autre qu'administrateur
  def can_be_destroyed?
    self.interventions.empty? && 
    self.conventions.empty? && 
    self.cotations.empty? && 
    self.commandes.empty? && 
    self.factures.empty? && 
    self.users.where.not(rôle: "administrateur").empty?
  end

  # TODO : Fusionner avec can_be_destroyed? ?
  def text_for_unauthorized_destroy
    return "" if can_be_destroyed?

    reasons = []

    reasons << "des interventions" if interventions.any?
    reasons << "des conventions"   if conventions.any?
    reasons << "des cotations"     if cotations.any?
    reasons << "des commandes"     if commandes.any?
    reasons << "des factures"      if factures.any?
    reasons << "des utilisateurs non administrateurs" if users.where.not(rôle: "administrateur").any?

    "Impossible de supprimer ce service car il est encore lié à #{reasons.to_sentence(locale: :fr)}."
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
