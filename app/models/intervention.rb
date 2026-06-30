# frozen_string_literal: true

class Intervention < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged
  include Workflow
  include WorkflowActiverecord

  acts_as_taggable_on :tags

  audited

  # Autorise Rails à lire et écrire ces champs virtuels pour le formulaire
  attr_accessor :tags_manager
  attr_accessor :début_prévue_hour, :début_prévue_minute, :fin_prévue_hour, :fin_prévue_minute, :début_hour,
                :début_minute, :fin_hour, :fin_minute

  before_destroy :must_not_have_any_mouvements

  belongs_to :service
  belongs_to :adherent, class_name: :User, foreign_key: :adherent_id, optional: true

  has_many :agent_interventions, dependent: :destroy
  has_many :agents, through: :agent_interventions, class_name: 'User'
  has_many :tool_interventions, dependent: :destroy
  has_many :tools, through: :tool_interventions
  has_many :mouvements

  has_one :organisation, through: :service

  has_many_attached :photos

  include PieceJointeValidable
  valide_piece_jointe :photos, types: PieceJointeValidable::IMAGES

  before_validation -> { combine_datetime(:début_prévue) }
  before_validation -> { combine_datetime(:fin_prévue) }
  before_validation -> { combine_datetime(:début) }
  before_validation -> { combine_datetime(:fin) }
  before_validation :check_absence
  before_validation :set_temporary_description, on: :create
  before_validation :check_workflow_pointage_mère

  validates :description, :adherent_id, :service_id, presence: true

  validate :schedules_must_make_sense
  validate :tools_must_be_available
  validate :agents_must_be_available
  validate :dates_cannot_be_in_the_future

  before_save -> { self.temps_de_pause = 0 if temps_de_pause.nil? }
  before_save :calc_temps_total

  scope :ordered, -> { order(updated_at: :desc) }

  after_create :replace_description_with_id
  after_create :calculate_co2, if: proc(&:terminé?)

  # after_create_commit :broadcast_to_authorized_viewers
  # after_create_commit au lieu de after_create pour être sûr que l'audit de création soit créé et utilisable
  after_create_commit :send_manager_notification

  # WORKFLOW
  NOUVEAU = 'nouveau'
  POINTAGE_ACTIVE = 'pointage activé'
  # ACCEPTE   = 'accepté'
  # EN_COURS  = 'en cours'
  TERMINE   = 'terminé'
  VALIDE    = 'validé'
  REFUSE    = 'refusé'
  ARCHIVE   = 'archivé'

  workflow do
    state NOUVEAU, meta: { style: 'badge-primary text-white', rgba: '0,181,255,255' } do
      # event :accepter, transitions_to: ACCEPTE
      event :terminer, transitions_to: TERMINE
    end
    state POINTAGE_ACTIVE, meta: { style: 'badge-warning text-white' }

    # state ACCEPTE, meta: {style: 'badge-primary text-white'} do
    #   event :en_cours, transitions_to: EN_COURS
    # end

    # state EN_COURS, meta: {style: 'badge-warning text-white'} do
    #   event :terminer, transitions_to: TERMINE
    # end

    state TERMINE, meta: { style: 'badge-accent text-white' } do
      event :valider, transitions_to: VALIDE
      event :refuser, transitions_to: REFUSE
    end

    state VALIDE, meta: { style: 'badge-success text-white' } do
      event :archiver, transitions_to: ARCHIVE
    end

    state REFUSE, meta: { style: 'badge-error text-white' } do
      # event :accepter, transitions_to: ACCEPTE
      event :archiver, transitions_to: ARCHIVE
    end

    state ARCHIVE, meta: { style: 'badge-ghost' }
  end

  # pour que le changement de 'workflow_state' se voit dans l'audit trail
  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end

  def style
    current_state.meta[:style]
  end

  def rgba
    current_state.meta[:rgba]
  end

  def self.workflow_states_count(interventions)
    results = interventions.reorder(:workflow_state).select(:id).group(:workflow_state).count(:id)
    h = {}
    workflow_state_humanized.each do |workflow_state|
      h[workflow_state] = results[workflow_state.downcase] || 0
    end
    h
  end

  def self.workflow_state_humanized
    workflow_spec.states.keys.map { |i| i.to_s.humanize }
  end

  # Retourne les interventions selon le role de l'utilisateur
  def self.by_role_for(user)
    case user.rôle
    when 'manager', 'administrateur'
      ordered
    when 'adhérent'
      user.interventions_adherent.ordered
    when 'agent'
      user.interventions.ordered
    end
  end

  # Retourne les interventions selon le role de l'utilisateur pour la page /home
  def self.by_role_for_home(user)
    case user.rôle
    when 'manager', 'administrateur'
      where.not(workflow_state: %w[validé refusé archivé]).ordered
    when 'adhérent'
      user.interventions_adherent.where(workflow_state: ['terminé']).ordered
    when 'agent'
      user.interventions.where(workflow_state: ['nouveau']).where.not(template_slug: nil).ordered
    end
  end

  def check_absence
    return unless agents.any?

    absence_ids = agents.flat_map do |agent|
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
        debut: début_prévue.try(:to_date), fin: fin_prévue.try(:to_date)
      ).pluck(:id)
    end.uniq

    return if absence_ids.empty?

    absences = Absence.where(id: absence_ids.uniq.flatten)
    messages = absences.includes(:user).map do |absence|
      "#{absence.user.nom_prénom} (du #{absence.du&.strftime('%d/%m/%Y')} au #{absence.au&.strftime('%d/%m/%Y')}, motif : '#{absence.motif}')"
    end
    errors.add(:interventions, ": Agent(s) indisponible(s) : #{messages.to_sentence}")
  end

  def self.get_unavailable_agents_with_absences(agent_ids, début_prévue, fin_prévue)
    conflicting_agents = []

    agent_ids.each do |agent_id|
      conflicting_agents += User
                            .find(agent_id)
                            .absences.where(
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
                              debut: début_prévue.try(:to_date), fin: fin_prévue.try(:to_date)
                            )
                            .pluck(:user_id)
    end

    conflicting_agents.uniq
  end

  def agents_must_be_available
    return if début_prévue.blank? && fin_prévue.blank?

    agents.each do |agent|
      conflicting_interventions = Intervention
                                  .joins(:agents)
                                  .where(agents: { id: agent.id })
                                  .where.not(id: id)
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

      next unless conflicting_interventions.exists?

      messages = conflicting_interventions.map do |conflict|
        " #{agent.nom} déjà sur l’intervention « #{conflict.description} » du #{conflict.début_prévue&.strftime('%d/%m/%Y %H:%M')} au #{conflict.fin_prévue&.strftime('%d/%m/%Y %H:%M')}"
      end
      errors.add('', "Conflit(s) détecté(s) sur un agent :#{messages.to_sentence}")
    end
  end

  def self.get_unavailable_agents(intervention_id, agent_ids, début_prévue, fin_prévue)
    agents = User.joins(:interventions).where(id: agent_ids)

    # Condition nécessaire si on est sur la création d'une intervention
    agents = agents.where.not('interventions.id = ?', intervention_id) if intervention_id

    agents = agents.where(
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

    agents.pluck(:id).uniq
  end

  def tools_must_be_available
    return if début_prévue.blank? && fin_prévue.blank?

    tools.each do |tool|
      conflicting_interventions = Intervention
                                  .joins(:tools)
                                  .where(tools: { id: tool.id })
                                  .where.not(id: id)
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

      next unless conflicting_interventions.exists?

      messages = conflicting_interventions.map do |conflict|
        " #{tool.name} déjà utilisé pour l’intervention « #{conflict.description} » du #{conflict.début_prévue&.strftime('%d/%m/%Y %H:%M')} au #{conflict.fin_prévue&.strftime('%d/%m/%Y %H:%M')}"
      end
      errors.add('', "Conflit(s) détecté(s) sur un outil :#{messages.to_sentence}")
    end
  end

  def self.get_unavailable_tools(intervention_id, tools_ids, début_prévue, fin_prévue)
    conflicting_tools = []

    tools_ids.each do |_tool|
      tools = Tool.joins(:interventions).where(id: tools_ids)

      # Condition nécessaire si on est sur la création d'une intervention
      tools = tools.where.not('interventions.id = ?', intervention_id) if intervention_id

      tools = tools.where(
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

      conflicting_tools += tools.pluck(:id)
    end
    conflicting_tools.uniq
  end

  def qrcode(url)
    RQRCode::QRCode.new(url).as_svg(
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 3,
      standalone: true,
      use_path: true
    )
  end

  def create_next_intervention(intervention_template, current_user)
    new_intervention = dup
    new_intervention.template_slug = slug
    new_intervention.début = DateTime.now
    new_intervention.fin = nil
    new_intervention.repeter = false
    new_intervention.workflow_state = 'nouveau'
    new_intervention.tags = tags
    new_intervention.service = intervention_template.service
    new_intervention.adherent = intervention_template.adherent
    new_intervention.agents = [current_user]

    new_intervention.save

    new_intervention
  end

  def pointages
    Intervention.where(template_slug: slug).order(updated_at: :desc)
  end

  def calc_temps_total
    if !fin || !début
      temps_total = 0
    elsif fin > début
      temps_total = (fin - début).seconds.in_hours - temps_de_pause
      temps_total *= agents.count
    else
      temps_total = 0
    end
    temps_total
  end

  def en_cours?
    return unless début && fin

    DateTime.now.between?(début, fin)
  end

  def durée_humanized
    Time.at(fin - début).utc.strftime('%Hh %Mmin')
  end

  def self.dernière_en_cours(interventions)
    now = DateTime.current

    interventions.where(
      "(début_prévue IS NOT NULL OR fin_prévue IS NOT NULL) AND
       (
         (début_prévue IS NULL AND fin_prévue >= :now) OR
         (fin_prévue IS NULL AND début_prévue <= :now) OR
         (début_prévue <= :now AND fin_prévue >= :now)
       )",
      now: now
    ).last
  end

  def passed
    !nouveau? || (fin && (fin < DateTime.now))
  end

  def schedules_must_make_sense
    if début_prévue && fin_prévue && (début_prévue > fin_prévue)
      errors.add(:erreur, ": La fin prévue de l'intervention ne peut pas être avant son commencement")
    end
    return unless début && fin && (début > fin)

    errors.add(:erreur, ": La fin de l'intervention ne peut pas être avant son commencement")
  end

  def self.filter_by_service(services)
    where(service: services)
  end

  def send_manager_notification
    user = User.find_by(id: audits.find_by(action: 'create')&.user&.id)
    if user&.adhérent?
      NotifManagersNewInterventionFromAdherentJob.perform_later(self, user)
    elsif user&.agent? && terminé?
      NotifManagersInterventionDoneByAgentJob.perform_later(self, user)
    end
  end

  def origin_location
    warehouse = agents.filter_map(&:warehouse).first

    # Si on a trouvé un warehouse valide avec des coordonnées
    if warehouse && warehouse.latitude.present? && warehouse.longitude.present?
      { lat: warehouse.latitude, lng: warehouse.longitude }
    else
      nil # On retourne nil explicite pour bloquer le calcul ensuite
    end
  end

  def calculate_co2
    return if Rails.env.test?
    # Les vérifications de base
    return unless service&.calculate_distance?
    return unless adherent && adherent.latitude.present? && adherent.longitude.present?

    origine = origin_location
    return unless origine.present?

    destination = { lat: adherent.latitude, lng: adherent.longitude }

    request = ApiGoogleMaps.new(origine, destination)
    request.call

    return unless request.errors.blank? && request.data_response['routes'].present?

    self.trajet = request.routes_info
    self.co2 = request.co2_consumption_by_route(request.data_response['routes'][0])
    save
  end

  def temps_par_agent
    # max au cas où il n'y a aucun agent
    temps_total / [agents.count, 1].max
  end

  def intervention_mère
    Intervention.find_by(slug: template_slug)
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

  def broadcast_to_authorized_viewers
    broadcast_channels.each do |channel|
      broadcast_prepend_to channel,
                           partial: 'interventions/intervention',
                           locals: { intervention: self, from_turbo_stream: true },
                           target: 'interventions'
    end
  end

  # Canaux Turbo Stream qui reçoivent le prepend d'une nouvelle intervention,
  # cf. l'abonnement par rôle dans interventions/index.html.erb :
  #   - organisation : les administrateurs (toute l'organisation)
  #   - service      : les managers dont l'intervention relève d'un de leurs services
  #   - adhérent     : l'adhérent rattaché à l'intervention
  #   - user         : chaque agent assigné
  def broadcast_channels
    channels = ["interventions_organisation_#{organisation.id}",
                "interventions_service_#{service_id}"]
    channels << "interventions_adherent_#{adherent_id}" if adherent_id.present?
    channels.concat(authorized_users_ids.map { |user_id| "interventions_user_#{user_id}" })
    channels
  end

  def authorized_users_ids
    user_ids = agents.pluck(:id)
    user_ids.compact!
    user_ids
  end

  def must_not_have_any_mouvements
    return unless mouvements.any?

    errors.add(:base, 'Il reste des mouvements liés.')
    throw(:abort)
  end

  def dates_cannot_be_in_the_future
    errors.add(:début, 'ne peut pas être dans le futur') if début.present? && début > Time.current

    return unless fin.present? && fin > Time.current

    errors.add(:fin, 'ne peut pas être dans le futur')
  end

  def set_temporary_description
    # Si la description est vide, on lui donne une valeur bouchon pour passer la validation
    self.description = 'en_attente_id' if description.blank?
  end

  def replace_description_with_id
    # Si la description est notre valeur bouchon, on la met à jour avec l'ID généré.
    # update_column met à jour directement en base sans redéclencher les validations/callbacks.
    return unless description == 'en_attente_id'

    update_column(:description, "##{id}")
  end

  # Ajoute ou enlève l'état 'pointage activé' selon si c'est un modèle de pointage.
  def check_workflow_pointage_mère
    if !repeter? && workflow_state == 'pointage activé'
      self.workflow_state = 'nouveau'
    elsif repeter? && workflow_state != 'pointage activé'
      self.workflow_state = 'pointage activé'
    end
  end
end
