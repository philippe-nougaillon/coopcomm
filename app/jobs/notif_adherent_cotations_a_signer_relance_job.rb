# frozen_string_literal: true

class NotifAdherentCotationsASignerRelanceJob < ApplicationJob
  queue_as :default

  # Envoie à l'adhérent la relance listant ses cotations restant à signer
  # (état « envoyé ») et trace l'envoi dans un MailLog.
  #
  # La sélection des adhérents à relancer et la garde des 48h sont faites en
  # amont par la tâche `cotations:relancer_adherents`. Le job re-dérive les
  # cotations à signer au moment de l'envoi : si l'adhérent a signé (ou n'a
  # plus rien à signer) entre-temps, on n'envoie rien.
  def perform(adherent)
    return if adherent&.email.blank?

    cotations = Cotation.kept.where(adherent: adherent, workflow_state: Cotation::ENVOYE).ordered.to_a
    return if cotations.empty?

    title = "[COOPCOMM] Rappel : #{'cotation'.pluralize(cotations.size)} à signer"

    mailer_response = NotificationMailer.cotations_a_signer_relance(adherent, cotations, title).deliver_now

    # rattaché à une cotation représentative, pour rattacher le log à la file cotations de l'adhérent (sert aussi à la garde des 48h).
    # ça aurait été mieux s'il on pouvait attacher un même mail_log à plusieurs cotations, ou faire un mail/mail_logs par cotation
    MailLog.create(organisation_id: cotations.first.organisation&.id, user_id: 0,
                   cotation_id: cotations.first.id,
                   message_id: mailer_response.message_id, to: adherent.email,
                   subject: title, channel: 0)
  end
end
