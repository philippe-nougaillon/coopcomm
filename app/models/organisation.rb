# frozen_string_literal: true

class Organisation < ApplicationRecord
  include PieceJointeValidable
  include PieceJointeAuditable

  audited

  has_many :mail_logs, dependent: :destroy
  has_many :absences, through: :users
  has_many :tools, dependent: :destroy
  has_many :mouvements, through: :tools
  # Ordre des callbacks = ordre de déclaration : après le matériel (une intervention qui garde un mouvement refuse de partir), avant les services (rattachement).
  before_destroy :supprimer_les_utilisateurs
  has_many :services, dependent: :destroy
  has_many :prestations, dependent: :destroy
  has_many :export_logs, dependent: :destroy
  has_many :warehouses, dependent: :destroy
  before_destroy :supprimer_les_audits
  has_many :users, -> { distinct }, through: :services
  has_many :messages, -> { distinct }, through: :users
  has_many :interventions, through: :services

  has_one_attached :logo do |attachable|
    attachable.variant :entete, format: :png, resize_to_limit: [1200, 180]
  end

  valide_image :logo

  validates :nom, presence: true
  validate :logo_convertible

  # Rails n'analyse qu'en tâche de fond, or les mails lisent la taille du logo ; après has_one_attached, qui envoie le fichier en after_commit.
  after_save_commit { logo.analyze if logo.attached? && !logo.analyzed? }

  # Un request_uuid commun aux audits de la cascade : ils servent de manifeste à #supprimer_les_audits.
  def destroy
    sans_uuid = Audited.store[:current_request_uuid].nil?
    Audited.store[:current_request_uuid] ||= SecureRandom.uuid
    ActualiserDashboard.regrouper { super }
  ensure
    Audited.store.delete(:current_request_uuid) if sans_uuid
  end

  private

  # Une demande née par mail peut n'avoir aucun service : les interventions partent avec leur adhérent.
  def supprimer_les_utilisateurs
    @ids_utilisateurs = users.with_discarded.ids
    Intervention.where(adherent_id: @ids_utilisateurs).find_each(&:destroy!)
    users.with_discarded.find_each(&:destroy!)
  end

  # Audited::Audit n'a aucun callback : delete_all n'y perd rien. Tranches de 10 000 : Postgres refuse plus de 65 535 paramètres liés.
  def supprimer_les_audits
    manifeste = Audited::Audit.where(request_uuid: Audited.store[:current_request_uuid], action: 'destroy')
    manifeste.pluck(:auditable_type, :auditable_id).group_by(&:first).each do |type, paires|
      paires.map(&:last).each_slice(10_000) { |ids| Audited::Audit.where(auditable_type: type, auditable_id: ids).delete_all }
    end
    Audited::Audit.where(user_id: @ids_utilisateurs).delete_all
  end

  # Le logo part converti dans les mails et les PDF : refusé dès le dépôt si ce serveur ne sait pas le convertir.
  def logo_convertible
    fichier = attachment_changes['logo'].try(:attachable)
    fichier = fichier[:io] if fichier.is_a?(Hash)
    return unless logo.variable? && fichier.respond_to?(:path)

    ActiveStorage::Variation.new(format: :png, resize_to_limit: [16, 16]).transform(fichier) { nil }
  rescue StandardError
    errors.add(:logo, 'illisible : enregistrez-le en PNG ou en JPEG')
  end
end
