# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'support@mg.coopcom.fr'
  layout 'mailer'
end
