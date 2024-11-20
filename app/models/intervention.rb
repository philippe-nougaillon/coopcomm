class Intervention < ApplicationRecord
  include Workflow
  include WorkflowActiverecord

  acts_as_taggable_on :tags

  audited

  belongs_to :organisation
  belongs_to :user
  belongs_to :agent, class_name: :User, foreign_key: :agent_id, optional: true 
  belongs_to :agent_binome, class_name: :User, foreign_key: :agent_binome_id, optional: true 
  belongs_to :adherent, class_name: :User, foreign_key: :adherent_id, optional: true 

  has_many_attached :photos

  validates :description, presence: true

  before_validation :check_absence

  scope :ordered, -> { order(updated_at: :desc) }

  # WORKFLOW
  NOUVEAU   = 'nouveau'
  # ACCEPTE   = 'accepté'
  # EN_COURS  = 'en cours'
  TERMINE   = 'terminé'
  VALIDE    = 'validé'
  REFUSE    = 'refusé'
  # ARCHIVE   = 'archivé'

  workflow do
    state NOUVEAU, meta: {style: 'badge-info text-white'} do
      # event :accepter, transitions_to: ACCEPTE
      event :terminer, transitions_to: TERMINE
    end

    # state ACCEPTE, meta: {style: 'badge-primary text-white'} do
    #   event :en_cours, transitions_to: EN_COURS
    # end

    # state EN_COURS, meta: {style: 'badge-warning text-white'} do
    #   event :terminer, transitions_to: TERMINE
    # end

    state TERMINE, meta: {style: 'badge-primary text-white'} do
      event :valider, transitions_to: VALIDE
      event :refuser, transitions_to: REFUSE
    end

    state VALIDE, meta: {style: 'badge-success text-white'} do
      # event :archiver, transitions_to: ARCHIVE
    end

    state REFUSE, meta: {style: 'badge-error text-white'} do
      # event :accepter, transitions_to: ACCEPTE
      # event :archiver, transitions_to: ARCHIVE
    end

    # state ARCHIVE, meta: {style: 'badge-ghost'}
  end

  # pour que le changement de 'workflow_state' se voit dans l'audit trail
  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end
  
  def style
    self.current_state.meta[:style]
  end

  def self.workflow_states_count(interventions)
    results = interventions.reorder(:workflow_state).select(:id).group(:workflow_state).count(:id)
    h = {}
    self.workflow_state_humanized.each do |workflow_state|
      h[workflow_state] = results[workflow_state.downcase] || 0
    end
    h
  end

  def self.workflow_state_humanized
    self.workflow_spec.states.keys.map{|i| i.to_s.humanize }
  end

  # retourne les interventions selon le scope de l'utilisateur
  def self.by_role_for(user)
    case user.rôle
    when 'manager'
      user.organisation.interventions.ordered
    when 'adhérent'
      user.organisation.interventions.where(adherent_id: user.id).ordered
    when 'agent'
      user.organisation.interventions.where("agent_id = :id OR agent_binome_id = :id", {id: user.id}).ordered
    when 'équipe'
      user.organisation.interventions.where(user_id: user.id)
    end
  end

  def check_absence
    absence_ids = []
    if self.agent
      absence_ids << self.agent.absences.where("absences.du BETWEEN ? AND ?", self.début, self.fin).pluck(:id)
    end
    if self.agent_binome
      absence_ids << self.agent_binome.absences.where("absences.du BETWEEN ? AND ?", self.début, self.fin).pluck(:id)
    end
    unless absence_ids.flatten.empty?
      errors.add(:interventions, ": Agent(s) '#{User.where(id: Absence.where(id: absence_ids.flatten).pluck(:user_id)).pluck(:nom).uniq.join(', ')}' pas disponible(s) à ces dates")
    end
  end

end
