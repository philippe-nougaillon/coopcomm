# frozen_string_literal: true

class ApplicationMailbox < ActionMailbox::Base
  # Une adresse en String est figée au chargement de la classe ; la lambda relit SUPPORT_EMAIL à chaque mail.
  routing ->(inbound_email) {
    inbound_email.mail.recipients.any? { |destinataire| destinataire.casecmp?(ENV.fetch('SUPPORT_EMAIL')) }
  } => :support
end
