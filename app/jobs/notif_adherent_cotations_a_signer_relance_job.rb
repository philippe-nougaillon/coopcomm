# frozen_string_literal: true

class NotifAdherentCotationsASignerRelanceJob < ApplicationJob
  queue_as :default

  # Les cotations sont re-dérivées ici : rien n'est envoyé si l'adhérent a signé
  # depuis la sélection faite par `cotations:relancer_adherents`.
  def perform(adherent)
    return if adherent&.email.blank?

    cotations = Cotation.kept.where(adherent: adherent, workflow_state: Cotation::ENVOYE).ordered.to_a
    return if cotations.empty?

    title = "[COOPCOMM] Rappel : #{'cotation'.pluralize(cotations.size)} à signer"

    mailer_response = NotificationMailer.cotations_a_signer_relance(adherent, cotations, title).deliver_now

    # Rattaché à une cotation représentative, faute de pouvoir lier un mail_log à plusieurs.
    MailLog.create(organisation_id: cotations.first.organisation&.id, user_id: 0,
                   cotation_id: cotations.first.id,
                   message_id: mailer_response.message_id, to: adherent.email,
                   subject: title, channel: 0)
  end
end
