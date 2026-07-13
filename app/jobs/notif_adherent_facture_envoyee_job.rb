# frozen_string_literal: true

class NotifAdherentFactureEnvoyeeJob < ApplicationJob
  queue_as :default

  # Envoie le mail « facture envoyée » à l'adhérent (avec PDF + copie à
  # l'émetteur) et trace l'envoi dans un MailLog.
  def perform(facture, adherent, user_id)
    sender = User.find_by(id: user_id)

    mailer_response = NotificationMailer.facture_envoyee(facture, adherent.email, sender&.email).deliver_now

    # On reprend le sujet du mail tel qu'envoyé : une seule source de vérité
    # (le mailer), pour que MailLog et l'email restent toujours synchronisés.
    MailLog.create(organisation_id: facture.organisation&.id, user_id: user_id,
                   message_id: mailer_response.message_id, to: adherent.email,
                   subject: mailer_response.subject, channel: 0)
  end
end
