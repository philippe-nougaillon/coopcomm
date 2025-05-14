class Notification < ApplicationRecord
  belongs_to :user, foreign_key: :from_id
  belongs_to :user, foreign_key: :to_id

  scope :ordered, -> { order(created_at: :desc) }

  after_create_commit -> { broadcast_prepend_to "notifications_#{self.to_id}",
                                                partial: "admin/notification_stream",
                                                locals: { notification: self },
                                                target: "notifications" }

end
