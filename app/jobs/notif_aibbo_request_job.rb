# frozen_string_literal: true

class NotifAibboRequestJob < ApplicationJob
  queue_as :default

  def perform(aibot_log)
    NotificationMailer.aibbo_request(aibot_log).deliver_now
  end
end
