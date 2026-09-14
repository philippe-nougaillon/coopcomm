# frozen_string_literal: true

class SupportMailbox < ApplicationMailbox
  def process
    Rails.logger.debug "SupportMailbox#process called with: #{mail.from_address&.address}"

    adherent = User.adhérent.find_by(email: mail.from_address&.address)
    return if adherent.nil?

    service = adherent.services.ordered.first
    return if service.nil?

    intervention = service.interventions.new(
      adherent_id: adherent.id,
      description: "[MAIL] #{mail.subject}",
      commentaires: "De #{adherent.nom_prenom_role} : #{safe_mail_body(mail)}"
    )

    if intervention.save
      NotifManagersNewInterventionFromAdherentJob.perform_later(intervention, adherent,
                                                               destinataires(adherent, service))
    else
      Rails.logger.error "SupportMailbox: intervention non créée pour #{adherent.email} : " \
                         "#{intervention.errors.full_messages.to_sentence}"
    end
  end

  private

  # to_a : ActiveJob ne sait pas sérialiser une relation, seulement des objets.
  def destinataires(adherent, service)
    return service.managers_and_admin.to_a if adherent.services.size == 1

    service.organisation.users.administrateur.to_a
  end

  def safe_mail_body(mail)
    body = mail.text_part&.decoded || mail.html_part&.decoded || mail.body.decoded

    # Si le body est nil ou pas une String, on renvoie une chaîne vide
    return '' unless body.is_a?(String)

    # Tente de forcer l'encodage en UTF-8 si ce n’est pas déjà le cas
    body = body.force_encoding('UTF-8') if body.encoding.name != 'UTF-8'

    # Si l'encodage est foireux, on nettoie à la hache 💥
    body = body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '�') unless body.valid_encoding?

    body
  end
end
