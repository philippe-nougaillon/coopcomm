# frozen_string_literal: true

class SupportMailbox < ApplicationMailbox
  def process
    Rails.logger.debug "SupportMailbox#process called with: #{mail.from_address&.address}"

    adherent = User.adhérent.find_by(email: mail.from_address&.address)
    return if adherent.nil?

    services = adherent.services.to_a
    return if services.empty?

    # Plusieurs services : la demande naît sans, un administrateur de l'organisation l'affecte.
    intervention = Intervention.new(
      adherent_id: adherent.id,
      service: (services.first if services.one?),
      service_facultatif: true,
      description: "[MAIL] #{mail.subject}",
      commentaires: "De #{adherent.nom_prenom_role} : #{safe_mail_body(mail)}",
      destinataires_notification: destinataires(adherent, services)
    )

    unless Audited.audit_class.as_user(adherent) { intervention.save }
      Rails.logger.error "SupportMailbox: intervention non créée pour #{adherent.email} : " \
                         "#{intervention.errors.full_messages.to_sentence}"
    end
  end

  private

  # to_a : ActiveJob ne sait pas sérialiser une relation, seulement des objets.
  def destinataires(adherent, services)
    return services.first.managers_and_admin.to_a if services.one?

    adherent.organisation.users.administrateur.to_a
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
