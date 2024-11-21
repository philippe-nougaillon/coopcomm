class Notification < ApplicationRecord
  belongs_to :user

  scope :ordered, -> { order(created_at: :desc) }

  after_create_commit -> { broadcast_prepend_to "notifications_#{self.user_id}",
                                                partial: "admin/notification_stream",
                                                locals: { notification: self },
                                                target: "notifications" }
end
