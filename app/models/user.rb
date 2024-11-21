class User < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited except: :notifications_last_seen_at


  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :rememberable, :timeoutable 
  devise :database_authenticatable,
         :recoverable,
         :validatable,
         :trackable,
         :registerable,
         :omniauthable,
         omniauth_providers: [:google_oauth2]

  belongs_to :organisation, optional: true
  has_many :interventions_agent, class_name: :Intervention, foreign_key: :agent_id
  has_many :interventions_agent_binome, class_name: :Intervention, foreign_key: :agent_binome_id
  has_many :interventions_adherent, class_name: :Intervention, foreign_key: :adherent_id
  has_many :notifications

  has_many :absences
  accepts_nested_attributes_for :absences, 
                              allow_destroy:true, 
                              reject_if: lambda {|attributes| attributes['du'].blank? || attributes['au'].blank? }

  normalizes :nom,    with: -> nom { nom.upcase.strip }
  normalizes :prénom, with: -> prénom { prénom.humanize.strip }

  enum rôle: {
    adhérent: 0,
    agent: 1,
    manager: 2,
    équipe: 3
  }

  enum service: {
    technique: 0,
    comptabilité: 1,
    informatique: 2,
    secrétariat: 3,
    périscolaire: 4,
    ménage: 5
  }

  scope :ordered, -> { order(:nom) }

  def self.grouped_agents(users)
    h = {}
    User.services.keys.each do |key|
      h[key.humanize] = users.agent.where(service: key).order(:nom).pluck(:nom, :id)
    end
    return h
  end

  def nom_prénom
    "#{self.nom} #{self.prénom}"
  end

  def nom_role
    "#{self.nom} (#{self.rôle.upcase})"
  end

  def super_admin?
    %w[philippe.nougaillon@gmail.com contact@philnoug.com pierreemmanuel.dacquet@gmail.com].include?(self.email)
  end

  def moyenne
    notes_agents  = self.interventions_agent.where.not(note: 0)
    notes_binomes = self.interventions_agent_binome.where.not(note: 0)
    count = notes_agents.count + notes_binomes.count

    unless count.zero?
      (notes_agents.sum(:note) + notes_binomes.sum(:note)).to_f / count
    else 
      nil
    end
  end

  def star_count(rating)
    rating_per_star = {}
    sum = 0
    (1..5).each do |i|
      rating_per_star[i] = self.interventions_agent.where(note: i).count + self.interventions_agent_binome.where(note: i).count
      sum += rating_per_star[i]
    end
    return (rating_per_star[rating].to_f / sum) * 100
  end

  def total_rating
    self.interventions_agent.where.not(note: 0).count + self.interventions_agent_binome.where.not(note: 0).count
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

  private

  def slug_candidates
    [SecureRandom.uuid]
  end

end
