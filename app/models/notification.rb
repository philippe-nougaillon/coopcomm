class Notification < ApplicationRecord
  belongs_to :from_user, class_name: "User", foreign_key: :from_id
  belongs_to :to_user, class_name: "User", foreign_key: :to_id

  scope :ordered, -> { order(created_at: :desc) }

  after_create_commit -> { broadcast_prepend_to "notifications_#{self.to_id}",
                                                partial: "admin/notification_stream",
                                                locals: { notification: self },
                                                target: "notifications" }

  def self.bad_words_regex
    bad_words = %w[
      connard connasse con enfoirée enfoiré putain merde couille
      salope pute enculée enculé bâtarde bâtard
      trouducul trouduc merde chiant chieuse
      abrutie abruti débile crétine crétin
      emmerdeuse emmerdeur casse-couilles
      glandu gland trou-du-cul
      bouffonne bouffon baltringue fumier ordure foutre
    ]

    /#{bad_words.join("|")}/i
  end

  def moderation
    self.message.gsub(Notification.bad_words_regex,'🌼🌼🌼')

  end

  def nb_bad_words
    self.message.scan(Notification.bad_words_regex).size
  end
end
