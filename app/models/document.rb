class Document < ApplicationRecord
  include Workflow
  include WorkflowActiverecord

  belongs_to :tool

  has_one_attached :fichier

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
end
