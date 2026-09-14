# frozen_string_literal: true

class NotifCotationSigneeJob < ApplicationJob
  queue_as :default

  # `triggered_by_id` = l'adhérent qui a signé, pas le destinataire.
  def perform(cotation, creator_id, triggered_by_id)
    creator = User.find_by(id: creator_id)
    return if creator&.email.blank?

    mailer_response = NotificationMailer.cotation_signee(cotation, creator.email).deliver_now

    # On reprend le sujet du mail tel qu'envoyé : une seule source de vérité
    # (le mailer), pour que MailLog et l'email restent toujours synchronisés.
    MailLog.create(organisation_id: cotation.organisation&.id, user_id: triggered_by_id,
                   cotation_id: cotation.id,
                   message_id: mailer_response.message_id, to: creator.email,
                   subject: mailer_response.subject, channel: 0)
  end
end
