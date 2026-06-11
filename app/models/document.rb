# frozen_string_literal: true

class Document < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  include Workflow
  include WorkflowActiverecord

  audited associated_with: :tool

  belongs_to :tool

  has_one_attached :fichier

  validates :category, uniqueness: { scope: %i[tool_id version] }

  before_validation :update_version

  NOUVEAU = 'nouveau'
  VALIDE = 'validé'
  REFUSE = 'refusé'

  workflow do
    state NOUVEAU, meta: { style: 'badge-warning' } do
      event :valider, transitions_to: VALIDE
      event :refuser, transitions_to: REFUSE
    end
    state VALIDE, meta: { style: 'badge-success' }
    state REFUSE, meta: { style: 'badge-error' }
  end

  def style
    current_state.meta[:style]
  end

  def update_version
    last_version = Document.where(tool_id: tool_id, category: category).maximum(:version) || 0
    self.version = last_version + 1
  end

  def self.categories
    %w[carte_grise certificat_assurance]
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
