class Commande < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Workflow
  include WorkflowActiverecord

  include Discard::Model

  audited associated_with: :adherent
  has_associated_audits

  belongs_to :adherent, class_name: 'User'
  belongs_to :service
  has_one :organisation, through: :service
  has_many :commande_lignes, dependent: :destroy

  CREE    = 'créé'
  ENVOYE  = 'envoyé'
  VALIDE  = 'validé'
  REFUSE  = 'refusé'
  ARCHIVE = 'archivé'

  workflow do
    state CREE, meta: { style: 'badge-ghost' } do
      event :envoyer, transitions_to: ENVOYE
    end
    state ENVOYE, meta: { style: 'badge-info text-white' } do
      event :valider, transitions_to: VALIDE
      event :refuser, transitions_to: REFUSE
    end
    state VALIDE, meta: { style: 'badge-success text-white' } do
      event :archiver, transitions_to: ARCHIVE
    end
    state REFUSE, meta: { style: 'badge-error text-white' } do
      # Une commande refusée peut être corrigée puis renvoyée (retour à « envoyé »).
      event :envoyer, transitions_to: ENVOYE
      event :archiver, transitions_to: ARCHIVE
    end
    state ARCHIVE, meta: { style: 'badge-neutral' }
  end

  validates :intitulé, presence: true

  before_create :assign_ref

  scope :ordered, -> { order(updated_at: :desc) }

  # Permet au changement de 'workflow_state' d'apparaître dans l'audit trail
  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end

  # Classe(s) CSS du badge selon l'état courant (définies dans le bloc workflow)
  def style
    current_state.meta[:style]
  end

  def self.workflow_state_humanized
    workflow_spec.states.keys.map { |state| state.to_s.humanize }
  end

  # Nom du fichier PDF (utilisé dans l'URL et l'en-tête Content-Disposition)
  def pdf_filename
    "Commande-#{ref}.pdf"
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
    n = Commande.where(service: org_services)
                .where('EXTRACT(YEAR FROM commandes.created_at) = ?', year)
                .count + 1
    self.ref = "#{year}-#{n}"
  end
end
