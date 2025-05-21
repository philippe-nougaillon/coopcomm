class NotifConfirmEmailNewsletterJob < ApplicationJob
  queue_as :default

  def perform(email)
    NotificationMailer.confirm_email_newsletter(email).deliver_now
  end
end
