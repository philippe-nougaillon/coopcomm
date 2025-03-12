class Document < ApplicationRecord
  include Workflow
  include WorkflowActiverecord

  audited associated_with: :tool

  belongs_to :tool

  has_one_attached :fichier

  validates :category, uniqueness: {scope: [:tool_id, :version]}

  before_validation :update_version



  NOUVEAU = 'nouveau'
  VALIDE = 'validé'
  REJETE = 'rejeté'

  workflow do
    state NOUVEAU, meta: {style: 'badge-warning'} do
      event :valider, transitions_to: VALIDE
      event :rejeter, transitions_to: REJETE
    end
    state VALIDE, meta: {style: 'badge-success'}
    state REJETE, meta: {style: 'badge-error'}
  end

  def style
    self.current_state.meta[:style]
  end

  def update_version
    self.version = Document.where(tool_id: self.tool_id, category: self.category).maximum(:version) + 1
  end

  def self.categories
    ['carte_grise', 'certificat_assurance']
  end
end
