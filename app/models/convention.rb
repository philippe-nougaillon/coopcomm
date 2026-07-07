# frozen_string_literal: true

class Convention < ApplicationRecord
  audited associated_with: :user

  belongs_to :user
  belongs_to :service
  has_one :organisation, through: :service

  has_one_attached :document

  include PieceJointeValidable
  valide_piece_jointe :document, types: PieceJointeValidable::DOCUMENTS

  validates :date_début, presence: true
  validates :date_fin_prévue, presence: true
  validate :one_convention_per_service
  validate :service_must_belong_to_adherent
  validate :end_date_after_start_date

  scope :ordered, -> { order(date_début: :desc) }

  # Filtre les conventions visibles par l'utilisateur courant :
  # - administrateur : celles de son organisation
  # - manager : uniquement celles des services qu'il gère
  # - autres : aucune
  def self.visible_to(user)
    if user.administrateur?
      joins(:service).where(services: { organisation_id: user.organisation&.id })
    elsif user.manager?
      where(service_id: user.service_ids)
    else
      none
    end
  end

  def temps_total_interventions
    # Si las fechas son nulas en las fixtures o pruebas, devolvemos 0 de inmediato
    return 0 if date_début.blank? || date_fin_prévue.blank?

    Intervention
            .where(adherent_id: user_id, service_id: service_id)
            .where(début: date_début.beginning_of_day..date_fin_prévue.end_of_day)
            .sum(:temps_total)
  end

  private

  def one_convention_per_service
    return if user_id.blank? || service_id.blank?

    exists = Convention.where(user_id: user_id, service_id: service_id)
                       .where.not(id: id)
                       .exists?
    return unless exists

    errors.add(:base, 'Cet adhérent a déjà une convention pour ce service.')
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
end
