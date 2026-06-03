class Cotation < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Discard::Model

  audited associated_with: :adherent
  has_associated_audits

  belongs_to :adherent, class_name: "User"
  belongs_to :service
  has_one :organisation, through: :service
  has_many :cotation_lignes, dependent: :destroy

  accepts_nested_attributes_for :cotation_lignes,
                                allow_destroy: true,
                                reject_if: ->(attributes) { attributes[:prestation_id].blank? }

  enum :statut, { 'créé': 0, 'envoyé': 1, 'validé': 2, 'refusé': 3, 'archivé': 4 }

  validates :intitulé, :statut, presence: true

  before_create :assign_ref

  scope :ordered, -> { order(updated_at: :desc) }

  # Nom du fichier PDF (utilisé dans l'URL et l'en-tête Content-Disposition)
  def pdf_filename
    "Cotation-#{ref}.pdf"
  end

  # Cotations visibles : un admin voit celles de son organisation,
  # un manager celles de ses services, les autres rôles aucune.
  def self.visible_to(user)
    if user.administrateur?
      joins(:service).where(services: { organisation_id: user.organisation&.id })
    elsif user.manager?
      where(service_id: user.service_ids)
    else
      none
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

  # Référence auto incrémentée par année et par organisation (ex. "2026-1")
  def assign_ref
    return if ref.present?

    year = Date.current.year
    org_services = Service.where(organisation_id: service&.organisation_id)
    n = Cotation.where(service: org_services)
                .where("EXTRACT(YEAR FROM cotations.created_at) = ?", year)
                .count + 1
    self.ref = "#{year}-#{n}"
  end
end
