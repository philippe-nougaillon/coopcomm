class Intervention < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  include Workflow
  include WorkflowActiverecord

  acts_as_taggable_on :tags

  audited

  attr_accessor :début_prévue_hour, :début_prévue_minute, :fin_prévue_hour, :fin_prévue_minute

  belongs_to :organisation
  belongs_to :team, class_name: :User, foreign_key: :team_id, optional: true
  belongs_to :adherent, class_name: :User, foreign_key: :adherent_id, optional: true
  has_many :agent_interventions, dependent: :destroy
  has_many :agents, through: :agent_interventions, class_name: 'User'
  has_many :tool_interventions, dependent: :destroy
  has_many :tools, through: :tool_interventions

  has_many_attached :photos

  validates :description, presence: true
  
  before_validation -> { combine_datetime(:début_prévue) }
  before_validation -> { combine_datetime(:fin_prévue) }
  before_validation :check_absence
  
  validate :tools_must_be_available

  before_save :calc_temps_total

  scope :ordered, -> { order(updated_at: :desc) }

  after_create_commit -> { broadcast_prepend_to "interventions_#{self.organisation.id}", 
                                              partial: "interventions/intervention", 
                                              locals: { intervention: self, from_turbo_stream: true }, 
                                              target: "interventions" }

  # WORKFLOW
  NOUVEAU   = 'nouveau'
  ATTENTE   = 'attente'
  # ACCEPTE   = 'accepté'
  # EN_COURS  = 'en cours'
  TERMINE   = 'terminé'
  VALIDE    = 'validé'
  REFUSE    = 'refusé'
  ARCHIVE   = 'archivé'

  workflow do
    state NOUVEAU, meta: {style: 'badge-info text-white', rgba: '0,181,255,255'} do
      # event :accepter, transitions_to: ACCEPTE
      event :terminer, transitions_to: TERMINE
    end
    state ATTENTE,  meta: {style: 'badge-warning text-white'}

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
      event :archiver, transitions_to: ARCHIVE
    end

    state REFUSE, meta: {style: 'badge-error text-white'} do
      # event :accepter, transitions_to: ACCEPTE
      event :archiver, transitions_to: ARCHIVE
    end

    state ARCHIVE, meta: {style: 'badge-ghost'}
  end

  # pour que le changement de 'workflow_state' se voit dans l'audit trail
  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end
  
  def style
    self.current_state.meta[:style]
  end

  def rgba
    self.current_state.meta[:rgba]
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
      user.interventions_adherent.ordered
    when 'agent'
      user.interventions.ordered
    when 'équipe'
      user.organisation.interventions.where(team_id: user.id)
    end
  end

  def check_absence
    if self.agents.any?
      absence_ids = []
      absence_ids = self.agents.flat_map do |agent|
        agent.absences.where(
          " (absences.du = :debut) OR
            (absences.du = :fin) OR
            (absences.au = :debut) OR
            (absences.au = :fin) OR
            (absences.du BETWEEN :debut AND :fin) OR
            (absences.au BETWEEN :debut AND :fin) OR
            (:debut BETWEEN absences.du AND absences.au) OR
            (:fin BETWEEN absences.du AND absences.au) OR
            (absences.du <= :debut AND absences.au >= :fin) OR
            (absences.du >= :debut AND absences.au <= :fin)
          ",
          debut: self.début_prévue.try(:to_date), fin: self.fin_prévue.try(:to_date)
        ).pluck(:id)
      end.uniq

      return if absence_ids.empty?

      absences = Absence.where(id: absence_ids.uniq.flatten)
      messages = absences.includes(:user).map do |absence|
        "#{absence.user.nom_prénom} (du #{absence.du.strftime('%d/%m/%Y')} au #{absence.au.strftime('%d/%m/%Y')}, motif : '#{absence.motif}')"
      end
      errors.add(:interventions, ": Agent(s) indisponible(s) : #{messages.to_sentence}")
    end
  end

  def tools_must_be_available
    return if début_prévue.blank? || fin_prévue.blank?

    tools.each do |tool|
      conflicting_interventions = Intervention
        .joins(:tools)
        .where(tools: { id: tool.id })
        .where.not(id: id) # exclut soi-même si mise à jour
        .where(
          " (interventions.début_prévue = :debut) OR
            (interventions.début_prévue = :fin) OR
            (interventions.fin_prévue = :debut) OR
            (interventions.fin_prévue = :fin) OR
            (interventions.début_prévue BETWEEN :debut AND :fin) OR
            (interventions.fin_prévue BETWEEN :debut AND :fin) OR
            (:debut BETWEEN interventions.début_prévue AND interventions.fin_prévue) OR
            (:fin BETWEEN interventions.début_prévue AND interventions.fin_prévue) OR
            (interventions.début_prévue <= :debut AND interventions.fin_prévue >= :fin) OR
            (interventions.début_prévue >= :debut AND interventions.fin_prévue <= :fin)
          ",
          debut: début_prévue, fin: fin_prévue
        )

        
      if conflicting_interventions.exists?
        messages = conflicting_interventions.map do |conflict|
          " #{tool.name} déjà utilisé pour l’intervention « #{conflict.description} » du #{conflict.début_prévue.strftime('%d/%m/%Y %H:%M')} au #{conflict.fin_prévue.strftime('%d/%m/%Y %H:%M')}"
        end
        errors.add("", "Conflit(s) détecté(s) sur un outil :#{messages.to_sentence}")
      end
    end
  end

  def qrcode(url)
    RQRCode::QRCode.new(url).as_svg(
                color: "000",
                shape_rendering: "crispEdges",
                module_size: 3,
                standalone: true,
                use_path: true)
  end

  def create_next_intervention
    new_intervention = self.dup
    new_intervention.template_slug = self.slug
    new_intervention.début = DateTime.now
    new_intervention.fin = nil
    new_intervention.repeter = false
    new_intervention.workflow_state = 'nouveau'
    new_intervention.tags = self.tags
    
    if new_intervention.save
      self.agent_interventions.each do |agent_intervention|
        new_intervention.agent_interventions.create(agent: agent_intervention.agent)
      end
    end

    new_intervention
  end

  def pointages
    Intervention.where(template_slug: self.slug).order(updated_at: :desc)
  end

  def calc_temps_total
    if !self.fin || !self.début
      temps_total = 0
    elsif self.fin > self.début
      temps_total = (self.fin - self.début).seconds.in_hours - self.temps_de_pause
      temps_total = temps_total * self.agents.count
    else
      temps_total = -1
    end
    temps_total
  end

  def en_cours?
    if self.début && self.fin
      DateTime.now.between?(self.début, self.fin)
    end
  end

  def durée_humanized
    Time.at(self.fin - self.début).utc.strftime("%Hh %Mmin")
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

  def combine_datetime(field)
    datetime = send(field)
    return if datetime.blank?

    hour = send("#{field}_hour").presence || datetime.hour
    minute = send("#{field}_minute").presence || datetime.min
    send("#{field}=", datetime.change(hour: hour.to_i, min: minute.to_i))
  end

end
