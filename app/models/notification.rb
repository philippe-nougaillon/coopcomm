class Notification < ApplicationRecord
  belongs_to :user, foreign_key: :from_id
  belongs_to :user, foreign_key: :to_id

  scope :ordered, -> { order(created_at: :desc) }

  after_create_commit -> { broadcast_prepend_to "notifications_#{self.to_id}",
                                                partial: "admin/notification_stream",
                                                locals: { notification: self },
                                                target: "notifications" }

  def message_modere
    bad_words = %w[
      connardouille connard connasse con enfoirée enfoiré
      salope pute enculée enculé bâtarde bâtard
      trouducul trouduc merde chiant chieuse
      abrutie abruti débile crétine crétin
      emmerdeuse emmerdeur casse-couilles
      glandu gland trou-du-cul
      bouffonne bouffon baltringue fumier ordure foutre
    ]

    regex = /#{bad_words.join("|")}/i

    self.message.gsub(regex,'***')
  end
end
