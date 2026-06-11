# frozen_string_literal: true

class NewOrganisationNotificationJob < ApplicationJob
  queue_as :default

  def perform(organisation)
    NotificationMailer.new_organisation(organisation).deliver_now
  end
end
