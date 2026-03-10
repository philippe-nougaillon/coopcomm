class User < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Discard::Model

  audited except: :notifications_last_seen_at

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable 
  devise :database_authenticatable,
         :recoverable,
        #  :validatable,
         :trackable,
         :lockable,
         :secure_validatable,
         :invitable
        #  :registerable,
        #  :omniauthable,
        #  omniauth_providers: [:google_oauth2]

  has_one_attached :profile_picture

  belongs_to :organisation, optional: true

  has_many :interventions_adherent, class_name: :Intervention, foreign_key: :adherent_id
  has_many :agent_interventions, foreign_key: :agent_id, class_name: 'AgentIntervention', dependent: :destroy
  has_many :interventions, through: :agent_interventions
  has_many :notifications, dependent: :destroy, foreign_key: :to_id, class_name: "Notification"
  has_many :absences, dependent: :destroy
  has_many :user_services, dependent: :destroy
  has_many :services, through: :user_services
  accepts_nested_attributes_for :absences, 
                              allow_destroy:true, 
                              reject_if: lambda {|attributes| attributes['du'].blank? || attributes['au'].blank? }

  normalizes :nom,    with: -> nom { nom.upcase.strip }
  normalizes :prénom, with: -> prénom { prénom.humanize.strip }

  enum :rôle, {
    adhérent: 0,
    agent: 1,
    manager: 2,
    équipe: 3
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
  validates :prénom, :rôle, presence: true, if: -> { rôle == "agent" }
  validates_uniqueness_of :email
  validates :localisation, presence: true, if: -> { rôle == "adhérent" }
  validates :localisation, format: {
    with: /\A\s*\d+(\.\d+)?\s*,\s*\d+(\.\d+)?\s*\z/,
    message: "doit être dans ce format : 123.123, 432.120398"
  }, allow_blank: true

  default_scope -> { kept }
  scope :ordered, -> { order(:nom) }

  def self.grouped_agents(users)
    h = {}
    Service.all.each do |service|
      h[service.nom] = users.agent.filter_by_service(service).order(:nom, :prénom).pluck(:nom, :prénom, :id).map { |nom, prénom, id| ["#{nom} #{prénom}", id] }
    end
    return h.sort_by { |k, _| I18n.transliterate(k) }.to_h
  end

  def nom_prénom
    "#{self.nom} #{self.prénom}"
  end

  def nom_prenom_role
    "#{self.nom_prénom} (#{self.rôle.upcase})"
  end

  def initiales
    "#{self.nom.first.upcase}#{self.prénom.first.upcase}"
  end

  def super_admin?
    %w[philippe.nougaillon@aikku.eu pierre-emmanuel.dacquet@aikku.eu sebastien.pourchaire@aikku.eu p-edacquet@hotmail.fr alexandre.meunier@aikku.eu].include?(self.email)
  end

  def moyenne
    notes_agents  = self.interventions.where(repeter: false)
    count = notes_agents.count

    unless count.zero?
      notes_agents.sum(:note).to_f / count
    else 
      nil
    end
  end

  def star_count(rating)
    rating_per_star = {}
    sum = 0
    (1..5).each do |i|
      rating_per_star[i] = self.interventions.where(note: i, repeter: false).count
      sum += rating_per_star[i]
    end
    # Si sum est à 0, sum devient 1 pour éviter une division par 0
    sum = sum == 0 ? 1 : sum
    return (rating_per_star[rating].to_f / sum) * 100
  end

  def total_rating
    self.interventions.where(repeter: false).count
  end

  def self.from_omniauth(auth)
    require "open-uri"

    if user = User.find_by(email: auth.info.email)
      user
    else
      find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0, 20]
        user.password_confirmation = user.password
        user.nom = auth.info.last_name   # assuming the user model has a name
        user.prénom = auth.info.first_name   # assuming the user model has a name
        # If you are using confirmable and the provider(s) you use validate emails, 
        # uncomment the line below to skip the confirmation emails.
        # user.skip_confirmation!

        user.organisation = Organisation.create(nom: "Organisation_#{SecureRandom.hex(5)}")
        user.rôle = "manager"
        
        user.save

        unless Rails.env.development?
          Events.instance.publish('organisation.created', payload: {user_id: user.id})
        end

        user
      end
    end
  end

  def dispatch_email_to_nom_prénom
    nom_prénom = self.email.split('@').first
    self.nom, self.prénom = nom_prénom.split('.')
  end

  def avatar
    case self.rôle
    when 'manager'
      'manage_accounts'
    when 'agent'
      'person'
    when "équipe"
      'group'
    when 'adhérent'
      'corporate_fare'
    end
  end

  def new_notifications?
    return self.notifications.where("notifications.created_at > ?", self.notifications_last_seen_at).any?
  end

  def current_absence(date = Date.today, periode = nil)
    absence = absences.where("du <= :date AND au >= :date", date: date).first
    
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

  def lng_lat
    # Inverse les variables pour correspondre aux valeurs de google
    self.localisation.gsub(/(.*?), (.*)/) { "[#{$2}, #{$1}]" }
  end

  def localisation_to_lat_lng_object
    # Sépare et nettoie la chaine localisation en latitude, longitude pour créer un objet contenant les coordonnées.
    lat, lng = self.localisation.split(',').map(&:strip).map(&:to_f)
    { lat: lat, lng: lng }
  end

  def nb_bad_words
    nb_bad_words = 0
    Notification.where(from_id: self.id).each do |notification|
      nb_bad_words += notification.nb_bad_words
    end
    nb_bad_words
  end

  def self.find_by_whatsapp_phone(phone)
    User.find_by(téléphone: phone.gsub("whatsapp:", ''))
  end

  def intervention_en_cours
    Intervention.dernière_en_cours(self.interventions)
  end

  def self.xls_headers
    ['Nom','Prénom','Email','Téléphone','Service','Mémo']
  end

  def self.generate_random_password
    # 1. Définition des bases en retirant les caractères prêtant à confusion
    minuscules = ('a'..'z').to_a - ['l']
    majuscules = ('A'..'Z').to_a - ['O', 'I']
    chiffres = ('1'..'9').to_a
    symboles = "!\"\#$%&'()*+,-./:;<=>?@[\\]^_`{|}~".chars

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
    initiator_id = self.try(:invited_by_id) || 0

    # 4. On crée le log pour Mailgun
    MailLog.create(
      user_id: initiator_id, 
      message_id: mailer_response.message_id, 
      to: self.email, 
      subject: mailer_response.subject || "Notification CoopComm",
      organisation_id: self.organisation_id,
      channel: 0
    )
  end

  def self.filter_by_service(services)
    joins(user_services: :service).where(services: services).distinct
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

end
