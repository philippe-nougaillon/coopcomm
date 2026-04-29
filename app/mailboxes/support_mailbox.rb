class SupportMailbox < ApplicationMailbox

  def process
    Rails.logger.debug "SupportMailbox#process called with: #{mail.from_address&.address}"

    # Chercher si l'envoyeur est un adhérent
    if user = User.where(rôle: "adhérent").find_by(email: mail.from_address&.address)

      # La création de l'intervention est basé sur le premier service de l'adhérent
      if service = Service.find_by(id: user.services.first)
        service.interventions.create(
                        adherent_id: (user.id),
                        description: "[MAIL] #{mail.subject}", 
                        commentaires: "De #{user.nom_prenom_role} : #{safe_mail_body(mail)}",
                      )
      end

    end
  end

  private

  def safe_mail_body(mail)
    body = mail.text_part&.decoded || mail.html_part&.decoded || mail.body.decoded
  
    # Si le body est nil ou pas une String, on renvoie une chaîne vide
    return "" unless body.is_a?(String)
  
    # Tente de forcer l'encodage en UTF-8 si ce n’est pas déjà le cas
    body = body.force_encoding("UTF-8") if body.encoding.name != "UTF-8"
  
    # Si l'encodage est foireux, on nettoie à la hache 💥
    unless body.valid_encoding?
      body = body.encode("UTF-8", invalid: :replace, undef: :replace, replace: "�")
    end
  
    body
  end

end