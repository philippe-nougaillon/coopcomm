# frozen_string_literal: true

class Convention < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  include Workflow
  include WorkflowActiverecord
  include PieceJointeValidable
  include PieceJointeAuditable

  audited associated_with: :user

  belongs_to :user, optional: true
  belongs_to :service, optional: true
  belongs_to :deposant, -> { with_discarded }, class_name: 'User', optional: true
  has_one :organisation, through: :service

  has_one_attached :document

  EN_ATTENTE = 'en_attente'
  ATTENTE_IA = 'attente_ia'
  EN_COURS = 'en_cours'
  ANALYSE = 'analysé'
  ECHEC = 'échec'
  VALIDE = 'validé'

  workflow do
    # Le premier état déclaré est celui d'une convention saisie à la main.
    state VALIDE, meta: { libelle: 'Validée', style: 'badge-success' }
    state EN_ATTENTE, meta: { libelle: 'En attente', style: 'badge-ghost' } do
      event :attendre_l_ia, transitions_to: ATTENTE_IA
      event :analyser, transitions_to: EN_COURS
      event :echouer, transitions_to: ECHEC
    end
    state ATTENTE_IA, meta: { libelle: "En attente de l'IA", style: 'badge-warning' } do
      event :analyser, transitions_to: EN_COURS
      event :echouer, transitions_to: ECHEC
    end
    state EN_COURS, meta: { libelle: 'Analyse en cours', style: 'badge-info' } do
      event :terminer, transitions_to: ANALYSE
      event :echouer, transitions_to: ECHEC
    end
    state ANALYSE, meta: { libelle: 'À valider', style: 'badge-primary' } do
      event :valider, transitions_to: VALIDE
    end
    state ECHEC, meta: { libelle: 'Échec', style: 'badge-error' } do
      event :relancer, transitions_to: EN_ATTENTE
      event :valider, transitions_to: VALIDE
    end
  end

  valide_document :document

  validates :user, :service, :date_début, presence: true, if: :validé?
  validates :heures_conventionnees, numericality: { greater_than: 0 }, if: :validé?
  validate :one_convention_per_service, if: :validé?
  validate :service_must_belong_to_adherent, if: :validé?
  validate :end_date_after_start_date
  validate :document_lisible_par_l_ia, on: :create, if: :en_attente?

  before_save :assign_ref, if: :validé?

  after_create_commit :annoncer_et_mettre_en_file, if: :deposant_id?
  # Joindre un document touche la convention, sans rien y changer : ce toucher n'est pas annoncé.
  after_update_commit :annoncer_le_changement, if: -> { deposant_id? && saved_changes.present? && (saved_change_to_workflow_state? || !validé?) }
  after_destroy_commit -> { diffuser(:remove) }, if: -> { deposant_id? && !validé? }

  scope :ordered, -> { order(date_début: :desc) }
  scope :en_analyse, -> { where(workflow_state: [EN_ATTENTE, ATTENTE_IA, EN_COURS]) }

  triable_par 'conventions.user' => ColonnesTri.utilisateur('conventions.user_id'),
              'conventions.ref' => :texte,
              'conventions.service' => ColonnesTri.service('conventions.service_id'),
              'conventions.date_début' => :brut,
              'conventions.heures_conventionnees' => :brut,
              'conventions.heures_consommees' => -> { '(SELECT COALESCE(SUM(interventions.temps_total), 0) FROM interventions ' \
                                                 'WHERE interventions.adherent_id = conventions.user_id ' \
                                                 'AND interventions.service_id = conventions.service_id ' \
                                                 "AND interventions.début >= GREATEST(conventions.date_début, '#{Date.current.beginning_of_year}') " \
                                                 "AND interventions.début < LEAST(conventions.date_fin_prévue, '#{Date.current.end_of_year}') + 1)" },
              'conventions.document' => "(SELECT #{TriTextuel.expression('active_storage_blobs.filename')} " \
                                        'FROM active_storage_attachments ' \
                                        'INNER JOIN active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id ' \
                                        "WHERE active_storage_attachments.record_id = conventions.id " \
                                        "AND active_storage_attachments.record_type = 'Convention' " \
                                        "AND active_storage_attachments.name = 'document')",
              'conventions.mémo' => :texte,
              'conventions.workflow_state' => :brut,
              'conventions.deposant' => ColonnesTri.utilisateur('conventions.deposant_id'),
              'conventions.created_at' => :brut,
              'conventions.updated_at' => :brut

  # Une convention en cours d'analyse n'est vue que de son déposant et des administrateurs de son organisation ; validée,
  # elle suit les services de l'utilisateur.
  def self.visible_to(user)
    validees = if user.administrateur?
                 with_validé_state.where(service_id: Service.where(organisation_id: user.organisation&.id).select(:id))
               elsif user.manager?
                 with_validé_state.where(service_id: user.service_ids)
               elsif user.adhérent?
                 with_validé_state.where(user_id: user.id)
               else
                 return none
               end
    return validees unless user.manager_or_admin?

    deposants = user.administrateur? ? User.with_discarded.by_service(Service.where(organisation_id: user.organisation&.id)) : user.id
    validees.or(without_validé_state.where(deposant_id: deposants))
  end

  def interventions
    Intervention
        .where(adherent_id: user_id, service_id: service_id)
        .where(début: date_début.beginning_of_day..date_fin_prévue&.end_of_day)
  end

  def heures_consommees
    self.interventions.where(début: Time.current.all_year).sum(:temps_total)
  end

  # Nom du fichier PDF (utilisé dans l'URL et l'en-tête Content-Disposition)
  def pdf_filename
    "Convention-#{ref}.pdf"
  end

  # Pour que le changement de 'workflow_state' se voie dans l'audit trail
  def persist_workflow_state(new_value)
    self[:workflow_state] = new_value
    save!
  end

  def libelle
    current_state.meta[:libelle]
  end

  def style
    current_state.meta[:style]
  end

  def organisation_du_deposant
    deposant&.organisation
  end

  # La convention validée du même adhérent pour le même service dont la période chevauche celle-ci.
  def concurrente
    return if user_id.blank? || service_id.blank?

    Convention.with_validé_state.where(user_id: user_id, service_id: service_id).where.not(id: id)
              .where(date_début: ..date_fin_prévue).where(date_fin_prévue: [nil, date_début..]).ordered.first
  end

  # Ce qui empêcherait la validation, sans rien changer à la convention.
  def erreurs_de_validation
    essai = dup
    essai.workflow_state = VALIDE
    essai.valid?
    essai.errors
  end

  private

  def one_convention_per_service
    errors.add(:base, 'Cet adhérent a déjà une convention pour ce service dans cette période.') if concurrente
  end

  def service_must_belong_to_adherent
    return if service.blank? || user.blank?

    return if user.services.include?(service)

    errors.add(:service, "n'est pas un service de cet adhérent.")
  end

  def end_date_after_start_date
    return if date_début.blank? || date_fin_prévue.blank?

    return unless date_fin_prévue < date_début

    errors.add(:date_fin_prévue, 'ne peut pas être antérieure à la date de début.')
  end

  def document_lisible_par_l_ia
    return errors.add(:document, :blank) unless document.attached?
    return if errors.include?(:document) || document.content_type == 'application/pdf'

    errors.add(:document, "format non pris en charge (#{document.content_type})")
  end

  # Référence auto incrémentée par année et par organisation, posée à la validation
  def assign_ref
    return if ref.present?

    year = Date.current.year
    org_services = Service.where(organisation_id: service&.organisation_id)
    n = Convention.with_validé_state.where(service: org_services)
                .where('EXTRACT(YEAR FROM conventions.created_at) = ?', year)
                .count + 1
    self.ref = "CONV-#{year}-#{n}"
  end

  def slug_candidates
    [SecureRandom.uuid]
  end

  def annoncer_et_mettre_en_file
    diffuser(:prepend, target: 'analyses')
    AnalyserConventionJob.perform_later(self) if en_attente?
  end

  # Une convention validée quitte la liste des analyses ; la page d'une analyse, rendue pour son lecteur, se recharge.
  def annoncer_le_changement
    diffuser(validé? ? :remove : :replace)
    broadcast_refresh
  end

  # Deux flux : celui du déposant, et celui de son organisation, que seuls les administrateurs écoutent.
  def diffuser(action, **options)
    options = options.merge(partial: 'conventions/analyse', locals: { convention: self }) unless action == :remove
    [deposant, organisation_du_deposant].compact.each { |destinataire| public_send(:"broadcast_#{action}_to", destinataire, :analyses, **options) }
  end

  def echouer(erreur)
    self.analyse = (analyse || {}).merge('erreur' => erreur)
  end

  def relancer
    self.analyse = analyse&.except('erreur')
  end
end
