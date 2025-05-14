class User < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited except: :notifications_last_seen_at

  validates :nom, :prénom, :email, presence: true
  validates :localisation, presence: true, if: -> { rôle == "adhérent" }
  validates :localisation, format: {
    with: /\A\s*\d+(\.\d+)?\s*,\s*\d+(\.\d+)?\s*\z/,
    message: "doit être dans ce format : 123.123, 432.120398"
  }, allow_blank: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable 
  devise :database_authenticatable,
         :recoverable,
         :validatable,
         :trackable
        #  :registerable,
        #  :omniauthable,
        #  omniauth_providers: [:google_oauth2]

  belongs_to :organisation, optional: true
  has_many :interventions_adherent, class_name: :Intervention, foreign_key: :adherent_id
  has_many :agent_interventions, foreign_key: :agent_id, class_name: 'AgentIntervention', dependent: :destroy
  has_many :interventions, through: :agent_interventions
  has_many :notifications, dependent: :destroy
  has_many :absences, dependent: :destroy
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

  enum :service, {
    Technique: 0,
    Comptabilité: 1,
    Informatique: 2,
    Secrétariat: 3,
    Périscolaire: 4,
    Ménage: 5
  }

  scope :ordered, -> { order(:nom) }

  def self.grouped_agents(users)
    h = {}
    User.services.keys.each do |key|
      h[key.humanize] = users.agent.where(service: key).order(:nom, :prénom).pluck(:nom, :prénom, :id).map { |nom, prénom, id| ["#{nom} #{prénom}", id] }
    end
    return h.sort_by { |k, _| I18n.transliterate(k) }.to_h
  end

  def nom_prénom
    "#{self.nom} #{self.prénom}"
  end

  def nom_prenom_role
    "#{self.nom_prénom} (#{self.rôle.upcase})"
  end

  def super_admin?
    %w[philippe.nougaillon@aikku.eu pierre-emmanuel.dacquet@aikku.eu sebastien.pourchaire@aikku.eu p-edacquet@hotmail.fr].include?(self.email)
  end

  def moyenne
    notes_agents  = self.interventions.where.not(note: 0)
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
      rating_per_star[i] = self.interventions.where(note: i).count
      sum += rating_per_star[i]
    end
    return (rating_per_star[rating].to_f / sum) * 100
  end

  def total_rating
    self.interventions.where.not(note: 0).count
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

  def absent?
    self.absences.where("DATE(?) BETWEEN absences.du AND absences.au", Date.today).any?
  end

  def current_absence(date = Date.today)
    self.absences.where("DATE(?) BETWEEN absences.du AND absences.au", date).first
  end

  def lng_lat
    # Inverse les variables pour correspondre aux valeurs de google
    self.localisation.gsub(/(.*?), (.*)/) { "[#{$2}, #{$1}]" }
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

end
