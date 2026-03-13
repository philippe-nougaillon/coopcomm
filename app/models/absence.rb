class Absence < ApplicationRecord
  audited associated_with: :user

  belongs_to :user

  scope :ordered, -> {order(du: :desc)}

  enum :motif, {
    congés_payés: 0,
    congé_parental: 1,
    formation: 2,
    congé_sans_solde: 3
  }

  # after_create_commit au lieu de after_create pour être sûr que l'audit de création soit créé et utilisable
  after_create_commit :send_manager_notification

  def en_cours?
    return (self.du..self.au).include?(Date.today)
  end

  def nb_jours
    (self.au - self.du).to_i + 1
  end

  def send_manager_notification
    NotifManagersNewAbsenceJob.perform_later(self)
  end
end
