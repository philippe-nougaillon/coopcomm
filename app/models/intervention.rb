# frozen_string_literal: true

class Intervention < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Workflow
  include WorkflowActiverecord
  include DashboardRefreshable
  include PieceJointeValidable
  include PieceJointeAuditable

  acts_as_taggable_on :tags

  audited

  # Autorise Rails à lire et écrire ces champs virtuels pour le formulaire
  attr_accessor :tags_manager
  attr_accessor :début_prévue_hour, :début_prévue_minute, :fin_prévue_hour, :fin_prévue_minute, :début_hour,
                :début_minute, :fin_hour, :fin_minute

  # Neutralise les publications d'événements de #apres_terminaison (clôture automatique).
  attr_accessor :sans_notification

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
  validate :dates_obligatoires_si_terminé

  before_save -> { self.temps_de_pause = 0 if temps_de_pause.nil? }
  before_save :calc_temps_total

  after_commit :update_heures_consommees_convention, if: -> { self.temps_total.present? }

  scope :ordered, -> { order(updated_at: :desc) }

  # montre tout action ou intervention qui ont ce status
  scope :courantes, -> { where(workflow_state: ['nouveau', 'pointage activé', 'terminé']) }

  # Pas de clause d'égalité pure : elle créerait de faux conflits entre
  # intervalles ouverts.
  def self.overlap_sql(debut_expr, fin_expr)
    # <<-SQL...SQL = chaîne multi-ligne (heredoc) ; #squish l'aplatit en une seule
    # ligne (retire retours à la ligne et espaces superflus) pour l'écrire lisiblement.
    <<-SQL.squish
      (#{debut_expr} BETWEEN :debut AND :fin) OR
      (#{fin_expr} BETWEEN :debut AND :fin) OR
      (:debut BETWEEN #{debut_expr} AND #{fin_expr}) OR
      (:fin BETWEEN #{debut_expr} AND #{fin_expr}) OR
      (#{debut_expr} <= :debut AND #{fin_expr} >= :fin) OR
      (#{debut_expr} >= :debut AND #{fin_expr} <= :fin)
    SQL
  end

  # Plage « effective » d'une intervention (côté BASE, ligne par ligne) : date
  # réelle si présente, sinon prévue. En phase avec #effective_début / #effective_fin.
  EFFECTIVE_DEBUT_SQL = 'COALESCE(interventions.début, interventions.début_prévue)'
  EFFECTIVE_FIN_SQL   = 'COALESCE(interventions.fin, interventions.fin_prévue)'

  # Chevauchement de la plage effective d'une intervention avec [:debut, :fin].
  OVERLAP_SQL = overlap_sql(EFFECTIVE_DEBUT_SQL, EFFECTIVE_FIN_SQL).freeze
  # Chevauchement d'une absence (colonnes du/au) avec [:debut, :fin].
  ABSENCE_OVERLAP_SQL = overlap_sql('absences.du', 'absences.au').freeze

  # Équivalent Ruby de EFFECTIVE_DEBUT_SQL / EFFECTIVE_FIN_SQL, à garder en phase.
  def effective_début
    début || début_prévue
  end

  def effective_fin
    fin || fin_prévue
  end

  # Un pointage OUVERT = fille de pointage (template_slug) dont la fin n'est pas
  # encore renseignée. Un agent ne peut en avoir qu'un seul à la fois.
  def pointage_ouvert?
    template_slug.present? && effective_fin.blank?
  end

  after_create :replace_description_with_id

  # Rafraîchit (de façon coalescée) les vues matérialisées du dashboard.
  after_commit :refresh_dashboard_views, on: %i[create destroy]
  after_commit :refresh_dashboard_views, on: :update, if: :dashboard_relevant_change?

  # after_create_commit :broadcast_to_authorized_viewers
  # after_create_commit au lieu de after_create pour être sûr que l'audit de création soit créé et utilisable
  after_create_commit :send_manager_notification

  # Déclaré en dernier : le `save` de #calculate_co2 fait perdre aux callbacks
  # suivants l'information « on sort d'une création ».
  after_commit :apres_terminaison, on: %i[create update], if: :vient_de_terminer?

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
    state NOUVEAU, meta: { style: 'badge-secondary text-white ', rgba: '0,181,255,255' } do
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

    state TERMINE, meta: { style: ' badge-primary text-white ' } do
      event :valider, transitions_to: VALIDE
      event :refuser, transitions_to: REFUSE
    end

    state VALIDE, meta: { style: ' badge-success text-white ' } do
      event :archiver, transitions_to: ARCHIVE
    end

    state REFUSE, meta: { style: ' badge-error text-white ' } do
      # event :accepter, transitions_to: ACCEPTE
      event :archiver, transitions_to: ARCHIVE
    end

    state ARCHIVE, meta: { style: 'badge-neutral' }
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
      user.interventions.where(workflow_state: ['nouveau']).ordered
    end
  end

  def check_absence
    return unless agents.any?

    absence_ids = agents.flat_map do |agent|
      agent.absences.where(
        ABSENCE_OVERLAP_SQL,
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

  # Check live du formulaire : ids des agents en absence sur [debut, fin].
  def self.get_unavailable_agents_with_absences(agent_ids, debut, fin)
    conflicting_agents = []

    agent_ids.each do |agent_id|
      conflicting_agents += User
                            .find(agent_id)
                            .absences.where(
                              ABSENCE_OVERLAP_SQL,
                              debut: debut.try(:to_date), fin: fin.try(:to_date)
                            )
                            .pluck(:user_id)
    end

    conflicting_agents.uniq
  end

  def agents_must_be_available
    agents_must_not_have_open_pointage
    return if effective_début.blank? && effective_fin.blank?

    agents.each do |agent|
      conflicting_interventions = Intervention
                                  .joins(:agents)
                                  .where(agents: { id: agent.id })
                                  .where.not(id: id)
                                  .where(OVERLAP_SQL, debut: effective_début, fin: effective_fin)

      next unless conflicting_interventions.exists?

      messages = conflicting_interventions.map do |conflict|
        " #{agent.nom} déjà sur l’intervention « #{conflict.description} » du #{conflict.effective_début&.strftime('%d/%m/%Y %H:%M')} au #{conflict.effective_fin&.strftime('%d/%m/%Y %H:%M')}"
      end
      errors.add('', "Conflit(s) détecté(s) sur un agent :#{messages.to_sentence}")
    end
  end

  # Deux intervalles ouverts ne se chevauchent pas au sens SQL : ce cas échappe
  # à OVERLAP_SQL.
  def agents_must_not_have_open_pointage
    return unless pointage_ouvert?

    agents.each do |agent|
      déjà_en_cours = Intervention
                      .joins(:agents)
                      .where(agents: { id: agent.id })
                      .where.not(id: id)
                      .where.not(template_slug: nil)
                      .where(fin: nil, fin_prévue: nil)

      next unless déjà_en_cours.exists?

      # Pointage ouvert : pas de fin effective, on affiche le début effectif.
      messages = déjà_en_cours.map do |conflict|
        " #{agent.nom_prénom} a déjà un pointage en cours pour l’intervention « #{conflict.description} » commencée le #{conflict.effective_début&.strftime('%d/%m/%Y %H:%M')}. Merci de terminer d'abord la première intervention."
      end
      errors.add('', "Conflit(s) détecté(s) :#{messages.to_sentence}")
    end
  end

  # TODO VU : mettre le contenu dans "get_unavailable_agents_with_interventions". "get_unavailable_agents" doit appeler "get_unavailable_agents_with_interventions" et "get_unavailable_agents_with_absences"
  # Check live du formulaire : ids des agents déjà occupés sur [debut, fin].
  def self.get_unavailable_agents(intervention_id, agent_ids, debut, fin)
    agents = User.joins(:interventions).where(id: agent_ids)

    # Condition nécessaire si on est sur la création d'une intervention
    agents = agents.where.not('interventions.id = ?', intervention_id) if intervention_id

    agents = agents.where(OVERLAP_SQL, debut: debut, fin: fin)

    agents.pluck(:id).uniq
  end

  def tools_must_be_available
    return if effective_début.blank? && effective_fin.blank?

    tools.each do |tool|
      conflicting_interventions = Intervention
                                  .joins(:tools)
                                  .where(tools: { id: tool.id })
                                  .where.not(id: id)
                                  .where(OVERLAP_SQL, debut: effective_début, fin: effective_fin)

      next unless conflicting_interventions.exists?

      messages = conflicting_interventions.map do |conflict|
        " #{tool.name} déjà utilisé pour l’intervention « #{conflict.description} » du #{conflict.effective_début&.strftime('%d/%m/%Y %H:%M')} au #{conflict.effective_fin&.strftime('%d/%m/%Y %H:%M')}"
      end
      errors.add('', "Conflit(s) détecté(s) sur un outil :#{messages.to_sentence}")
    end
  end

  # Check live du formulaire : ids des outils déjà utilisés sur [debut, fin].
  def self.get_unavailable_tools(intervention_id, tools_ids, debut, fin)
    conflicting_tools = []

    tools_ids.each do |_tool|
      tools = Tool.joins(:interventions).where(id: tools_ids)

      # Condition nécessaire si on est sur la création d'une intervention
      tools = tools.where.not('interventions.id = ?', intervention_id) if intervention_id

      tools = tools.where(OVERLAP_SQL, debut: debut, fin: fin)

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
      temps_total = (fin - début).seconds.in_hours - temps_de_pause.to_f
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
    response = self.get_routes_info_from_location

    return if response['errors'].present? && response.dig('data_response', 'routes').blank?

    self.trajet = response['routes_info']
    self.co2 = FetchRoutesInfos.co2_consumption_by_route(response.dig('data_response', 'routes', 0))
    save
  end

  def temps_par_agent
    # max au cas où il n'y a aucun agent
    temps_total / [agents.count, 1].max
  end

  def intervention_mère
    Intervention.find_by(slug: template_slug)
  end

  def pointage_de?(user)
    template_slug.present? && intervention_mère&.agents&.include?(user)
  end

  def update_heures_consommees_convention
    associated_convention = Convention
                        .where("date_début <= ? AND date_fin_prévue >= ?", self.début, self.début)
                        .find_by(user_id: self.adherent_id, service_id: self.service_id)

    if associated_convention.present?
      last_audit = self.audits.last

      # Si la dernière modification contient le temps_total, on met à jour le nombre d'heures consommees de la convention associé à l'intervention
      if last_audit.audited_changes["temps_total"]
        new_temps_total = extract_temps_total_depending_on_audit(last_audit)

        associated_convention.heures_consommees += new_temps_total
        associated_convention.save(validate: false)
      end
    end
  end

  # Retourne le temps total à ajouter en fonction de l'action en cours (un nombre pour create et destroy, un array pour un update)
  def extract_temps_total_depending_on_audit(last_audit)
    temps_total_audit = last_audit.audited_changes["temps_total"]
    
    # Dans le cas d'un create, on ajoute la valeur
    if last_audit.action == "create" && temps_total_audit.is_a?(Numeric)
      temps_total_audit
    # Dans le cas d'un destroy, on enleve la valeur
    elsif last_audit.action == "destroy" && temps_total_audit.is_a?(Numeric)
      temps_total_audit * (-1)
    # Dans le cas d'un update, on ajoute la différence entre l'ancienne (first) et la nouvelle valeur (last)
    elsif last_audit.action == "update" && temps_total_audit.is_a?(Array)
      (temps_total_audit.last - temps_total_audit.first)
    else
      0
    end
  end

  def bon?
    User.find_by(id: audits.first&.user_id)&.agent?
  end

  def get_routes_info_from_location
    localisation_depart = self.origin_location

    # On vérifie que l'intervention possède un adhérent localisé ET que le service nécessite le calcul
    if localisation_depart && self.adherent.present? && self.adherent.latitude.present? && self.adherent.longitude.present? && self.service&.calculate_distance?

      localisation_arrivee = { lat: self.adherent.latitude, lng: self.adherent.longitude }

      # Création du service avec le départ et l'arrivée
      FetchRoutesInfos.call(localisation_depart, localisation_arrivee)
    else
      {}
    end
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

  def dates_obligatoires_si_terminé
    return unless terminé?

    errors.add(:début, "est obligatoire pour terminer l'intervention") if début.blank?
    errors.add(:fin, "est obligatoire pour terminer l'intervention") if fin.blank?
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

  def vient_de_terminer?
    terminé? && saved_change_to_workflow_state?
  end

  def apres_terminaison
    calculate_co2

    return if Rails.env.development? || sans_notification

    Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: id })

    # Un pointage a son propre événement, publié par interventions#pointer.
    Events.instance.publish('intervention.done', payload: { intervention_id: id }) if template_slug.blank?
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
