# frozen_string_literal: true

class Convention < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  
  include PieceJointeValidable
  include PieceJointeAuditable

  audited associated_with: :user

  belongs_to :user
  belongs_to :service
  has_one :organisation, through: :service

  has_one_attached :document

  valide_document :document

  validates :date_début, presence: true
  validates :date_fin_prévue, presence: true
  validate :one_convention_per_service
  validate :service_must_belong_to_adherent
  validate :end_date_after_start_date
  
  before_create :assign_ref

  scope :ordered, -> { order(date_début: :desc) }

  triable_par 'conventions.user' => ColonnesTri.utilisateur('conventions.user_id'),
              'conventions.ref' => :texte,
              'conventions.service' => ColonnesTri.service('conventions.service_id'),
              'conventions.date_début' => :brut,
              'conventions.heures_consommees' => '(SELECT COALESCE(SUM(interventions.temps_total), 0) FROM interventions ' \
                                                 'WHERE interventions.adherent_id = conventions.user_id ' \
                                                 'AND interventions.service_id = conventions.service_id ' \
                                                 'AND interventions.début >= conventions.date_début ' \
                                                 'AND interventions.début < conventions.date_fin_prévue + 1)',
              'conventions.document' => "(SELECT #{TriTextuel.expression('active_storage_blobs.filename')} " \
                                        'FROM active_storage_attachments ' \
                                        'INNER JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id ' \
                                        "WHERE active_storage_attachments.record_id = conventions.id " \
                                        "AND active_storage_attachments.record_type = 'Convention' " \
                                        "AND active_storage_attachments.name = 'document')",
              'conventions.mémo' => :texte

  def self.visible_to(user)
    if user.administrateur?
      joins(:service).where(services: { organisation_id: user.organisation&.id })
    elsif user.manager?
      where(service_id: user.service_ids)
    elsif user.adhérent?
      where(user_id: user.id)
    else
      none
    end
  end

  def interventions
    Intervention
        .where(adherent_id: user_id, service_id: service_id)
        .where(début: date_début.beginning_of_day..date_fin_prévue.end_of_day)
  end

  def heures_consommees
    self.interventions.sum(:temps_total)
  end

  private

  def one_convention_per_service
    return if user_id.blank? || service_id.blank?

    exists = Convention.where(user_id: user_id, service_id: service_id)
                       .where.not(id: id)
                       .where(date_début: ..date_fin_prévue) # La date de fin ne doit pas chevaucher la date de début
                       .where(date_fin_prévue: date_début..) # Inversement
                       .exists?
    return unless exists

    errors.add(:base, 'Cet adhérent a déjà une convention pour ce service dans cette période.')
  end

  def service_must_belong_to_adherent
    return if service.blank? || user.blank?

    return if user.services.include?(service)

    errors.add(:service, "n'est pas un service de cet adhérent.")
  end

  def end_date_after_start_date
    return if date_début.blank? || date_fin_prévue.blank?

    return unless date_fin_prévue < date_début

    errors.add(:date_fin_prévue, 'ne peut pas être antérieure à la date de début.')
  end

  # Référence auto incrémentée par année et par organisation
  def assign_ref
    return if ref.present?

    year = Date.current.year
    org_services = Service.where(organisation_id: service&.organisation_id)
    n = Convention.where(service: org_services)
                .where('EXTRACT(YEAR FROM conventions.created_at) = ?', year)
                .count + 1
    self.ref = "CONV-#{year}-#{n}"
  end

  def slug_candidates
    [SecureRandom.uuid]
  end
end
