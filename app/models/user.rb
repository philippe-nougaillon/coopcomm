# frozen_string_literal: true

class User < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Discard::Model
  include PieceJointeValidable
  include PieceJointeAuditable

  acts_as_taggable_on :tags

  audited except: :messages_last_seen_at

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :database_authenticatable,
         :recoverable,
         #  :validatable,
         :trackable,
         #  :lockable,
         :secure_validatable,
         :invitable,
         :rememberable
  #  :registerable,
  #  :omniauthable,
  #  omniauth_providers: [:google_oauth2]

  has_one_attached :profile_picture

  IMAGES = %w[
    image/png
    image/jpeg
    image/jpg
    image/webp
    image/avif
  ].freeze

  valide_piece_jointe :profile_picture, types: IMAGES

  belongs_to :warehouse, optional: true

  has_many :interventions_adherent, class_name: :Intervention, foreign_key: :adherent_id
  has_many :cotations_adherent, class_name: 'Cotation', foreign_key: :adherent_id, dependent: :destroy
  has_many :commandes_adherent, class_name: 'Commande', foreign_key: :adherent_id, dependent: :destroy
  has_many :factures_adherent, class_name: 'Facture', foreign_key: :adherent_id, dependent: :destroy
  has_many :agent_interventions, foreign_key: :agent_id, class_name: 'AgentIntervention', dependent: :destroy
  has_many :interventions, through: :agent_interventions
  has_many :messages, dependent: :destroy, foreign_key: :to_id, class_name: 'Message'
  has_many :absences, dependent: :destroy
  has_many :conventions, dependent: :destroy
  has_many :user_services, dependent: :destroy
  has_many :services, through: :user_services

  # L'utilisateur n'est associé qu'à une seule organisation, via ses services
  has_many :organisations, -> { limit(1) }, through: :services

  accepts_nested_attributes_for :absences,
                                allow_destroy: true,
                                reject_if: ->(attributes) { attributes['du'].blank? || attributes['au'].blank? }

  normalizes :nom,    with: ->(nom) { nom.upcase.strip }
  normalizes :prénom, with: ->(prénom) { prénom.humanize.strip }

  enum :rôle, {
    adhérent: 0,
    agent: 1,
    manager: 2,
    administrateur: 3
  }

  # enum :service, {
  #   Technique: 0,
  #   Comptabilité: 1,
  #   Informatique: 2,
  #   Secrétariat: 3,
  #   Périscolaire: 4,
  #   Ménage: 5
  # }

  validates :nom, :email, presence: true
  validates :prénom, :rôle, presence: true, if: -> { rôle == 'agent' }
  validates_uniqueness_of :email
  validates :address, :latitude, :longitude, presence: true, if: -> { rôle == 'adhérent' }
  validate :must_have_at_least_one_service
  validate :agent_must_have_exactly_one_service, if: -> { rôle == 'agent' }

  default_scope -> { kept }
  scope :ordered, -> { order(:nom) }

  def organisation
    organisations.first
  end

  def self.grouped_agents(user)
    # 1. On stocke les IDs des services de l'utilisateur courant pour filtrer
    user_service_ids = user.service_ids

    # 2. On récupère les agents uniques qui appartiennent à au moins un de ces services
    # Le .includes(:services) est crucial ici pour éviter le problème des requêtes N+1
    agents = User.intervenants
                 .joins(:services)
                 .where(services: { id: user_service_ids })
                 .distinct
                 .includes(:services)

    # 3. On initialise un Hash qui créera un tableau vide automatiquement pour toute nouvelle clé
    h = Hash.new { |hash, key| hash[key] = [] }

    # 4. On trie les agents et on construit nos groupes
    agents.sort_by { |a| [a.nom.to_s, a.prénom.to_s] }.each do |agent|
      # On ne garde que les services de l'agent qui sont en commun avec l'utilisateur courant
      # (Optionnel : si tu veux afficher TOUS les services de l'agent, enlève le .select)
      services_communs = agent.services.select { |s| user_service_ids.include?(s.id) }

      # On trie les noms pour garantir que "Ménage - Technique" et "Technique - Ménage"
      # aillent dans le même groupe, puis on les assemble.
      nom_groupe = services_communs.map(&:nom).sort.join(' - ')

      # Sécurité au cas où
      nom_groupe = 'Sans service' if nom_groupe.blank?

      # On ajoute l'agent dans le groupe correspondant
      h[nom_groupe] << ["#{agent.nom} #{agent.prénom}", agent.id]
    end

    # 5. On retourne le Hash trié alphabétiquement par le nom du groupe
    h.sort_by { |k, _| I18n.transliterate(k) }.to_h
  end

  # Liste plate au format [["NOM Prénom", id], …].
  def self.agents_for_services(services)
    intervenants
      .by_service(services)
      .order(:nom, :prénom)
      .map { |agent| ["#{agent.nom} #{agent.prénom}", agent.id] }
  end

  def nom_prénom
    "#{nom} #{prénom}"
  end

  def nom_prenom_role
    "#{nom_prénom} (#{rôle.upcase})"
  end

  def initiales
    "#{nom.first.upcase}#{prénom.first.upcase}"
  end

  def super_admin?
    ENV['SUPER_ADMIN'].to_s.split(',').include?(email)
  end

  def moyenne
    rated_interventions.average(:note)&.to_f
  end

  def star_count(rating)
    rating_per_star = {}
    sum = 0
    (1..5).each do |i|
      rating_per_star[i] = interventions.where(note: i, repeter: false).count
      sum += rating_per_star[i]
    end
    # Si sum est à 0, sum devient 1 pour éviter une division par 0
    sum = sum.zero? ? 1 : sum
    (rating_per_star[rating].to_f / sum) * 100
  end

  def rated_interventions
    interventions.where(repeter: false).where.not(note: nil)
  end

  def total_rating
    rated_interventions.count
  end

  def self.from_omniauth(auth)
    require 'open-uri'

    if (user = User.find_by(email: auth.info.email))
      user
    else
      find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
        user.password_confirmation = user.password
        user.nom = auth.info.last_name # assuming the user model has a name
        user.prénom = auth.info.first_name # assuming the user model has a name
        # If you are using confirmable and the provider(s) you use validate emails,
        # uncomment the line below to skip the confirmation emails.
        # user.skip_confirmation!

        user.organisation = Organisation.create(nom: "Organisation_#{SecureRandom.hex(5)}")
        user.rôle = 'administrateur'

        user.save

        Events.instance.publish('organisation.created', payload: { user_id: user.id }) unless Rails.env.development?

        user
      end
    end
  end

  def dispatch_email_to_nom_prénom
    nom_prénom = email.split('@').first
    self.nom, self.prénom = nom_prénom.split('.')
  end

  def avatar
    case rôle
    when 'manager'
      'manage_accounts'
    when 'agent'
      'person'
    when 'adhérent'
      'corporate_fare'
    when 'administrateur'
      'supervisor_account'
    end
  end

  def new_messages?
    # On récupère les messages de l'utilisateur non lues. Filtrage des from_id par service pour éviter les utilisateurs supprimés.
    Message.where(to_id: id, from_id: User.by_service(services).ids, read_at: nil).any?
  end

  def current_absence(date = Date.today, periode = nil)
    absence = absences.where('du <= :date AND au >= :date', date: date).first

    # S'il n'y a aucune absence à cette date, on renvoie nil direct
    return nil unless absence

    # Si on ne demande pas de période précise, on renvoie l'absence trouvée
    return absence if periode.nil?

    # Si c'est une journée complète (les deux booléens sont à false),
    # l'absence est valide peu importe la période demandée
    journee_entiere = !absence.matin && !absence.après_midi
    return absence if journee_entiere

    # Si c'est une demi-journée, on vérifie si elle correspond à la demande
    if periode == :matin && absence.matin
      return absence
    elsif periode == :apres_midi && absence.après_midi
      return absence
    end

    # Si l'absence ne correspond pas à la période (ex: on demande le matin,
    # mais l'absence est posée pour l'après-midi), on renvoie nil
    nil
  end

  # La méthode absent? devient ultra minimaliste puisqu'elle se base sur current_absence
  def absent?(date = Date.today, periode = nil)
    current_absence(date, periode).present?
  end

  def nb_bad_words
    nb_bad_words = 0
    Notification.where(from_id: id).each do |message|
      nb_bad_words += message.nb_bad_words
    end
    nb_bad_words
  end

  def self.find_by_whatsapp_phone(phone)
    User.find_by(téléphone: phone.gsub('whatsapp:', ''))
  end

  def intervention_en_cours
    Intervention.dernière_en_cours(interventions)
  end

  def self.xls_headers
    %w[Nom Prénom Email Téléphone Service Mémo]
  end

  def self.generate_random_password
    # 1. Définition des bases en retirant les caractères prêtant à confusion
    minuscules = ('a'..'z').to_a - ['l']
    majuscules = ('A'..'Z').to_a - %w[O I]
    chiffres = ('1'..'9').to_a
    symboles = "!@\#$%&*-+=?".chars

    tous_les_caracteres = minuscules + majuscules + chiffres + symboles

    # 2. Garantie d'avoir au moins un caractère de chaque type
    mot_de_passe = [
      minuscules.sample(random: SecureRandom),
      majuscules.sample(random: SecureRandom),
      chiffres.sample(random: SecureRandom),
      symboles.sample(random: SecureRandom)
    ]

    # 3. Remplissage pour atteindre 12 caractères
    8.times do
      mot_de_passe << tous_les_caracteres.sample(random: SecureRandom)
    end

    # 4. Mélange sécurisé et conversion en chaîne (String)
    mot_de_passe.shuffle(random: SecureRandom).join
  end

  def send_devise_notification(notification, *args)
    # 1. On prépare l'email (quelle que soit la notification)
    mail = devise_mailer.send(notification, self, *args)

    # 2. On l'envoie immédiatement pour récupérer l'objet Mail::Message
    mailer_response = mail.deliver_now

    # 3. On détermine qui est à l'origine de l'email
    # Si c'est une invitation, on prend l'ID de l'inviteur (current_user).
    # Sinon, on considère que c'est l'utilisateur lui-même (ex: mot de passe oublié).
    initiator_id = try(:invited_by_id) || 0

    # 4. On crée le log pour Mailgun
    # L'organisation dérive des services : un compte qui n'en a plus aucun ne
    # doit pas faire échouer l'envoi du mail, seulement sa traçabilité.
    return if organisation.nil?

    MailLog.create(
      user_id: initiator_id,
      message_id: mailer_response.message_id,
      to: email,
      subject: mailer_response.subject || 'Notification CoopComm',
      organisation_id: organisation.id,
      channel: 0
    )
  end

  def self.by_service(services)
    joins(user_services: :service)
      .where(services: services)
      .distinct
  end

  def manager_or_admin?
    manager? || administrateur?
  end

  def self.intervenants
    where(rôle: %w[agent manager administrateur])
  end

  # Retourne la liste des roles que l'utilisateur a le droit de voir
  def assignable_roles
    if manager? || agent?
      ['agent']
    else
      User.rôles.keys
    end
  end

  def remember_me
    true
  end

  def find_current_intervention(slug_intervention_pointage)
    Intervention
              .joins(:agent_interventions)
              .where(template_slug: slug_intervention_pointage)
              .where(agent_interventions: { agent_id: self.id })
              .where('DATE(début) = ?', Date.today)
              .where(workflow_state: 'nouveau') # Seul les nouvelles interventions nous intéresse
              .order(updated_at: :asc) # Trie du plus ancien au plus récent
              .last # Prend l'intervention créée/modifiée la plus récente
  end

  def get_services_by_role
    if self.administrateur?
      self.organisation.services.ordered
    else
      self.services.ordered
    end
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

  # Les rattachements marqués pour destruction ne comptent pas : on valide l'état
  # d'après la sauvegarde, pas celui d'avant.
  def services_restants
    user_services.reject(&:marked_for_destruction?)
  end

  def must_have_at_least_one_service
    return unless services_restants.empty?

    errors.add(:services, 'doit comporter au moins un service')
  end

  def agent_must_have_exactly_one_service
    return if services_restants.size <= 1

    errors.add(:services, 'ne doit comporter qu\'un seul service pour un agent')
  end
end
