class SupportMailbox < ApplicationMailbox

  def process
    organisation_id = nil
    from_email = mail.from_address.to_s.split('<').last.split('>').first
    # puts "email : #{from_email}"
    # puts 'avant check adhérent/manager'
    # Chercher si l'envoyeur est un adhérent ou un manager
    if user = User.where(rôle: [0,2]).find_by(email: from_email)
      # puts 'pendant check adhérent/manager'
      organisation_id = user.organisation_id
      # puts "organisation_id : #{organisation_id}"

      if organisation_id
        organisation = Organisation.find(organisation_id)
        # puts "organisation : #{organisation.inspect}"
        intervention = organisation.interventions.new( 
                        adherent_id: user.id, 
                        user_id: user.id,
                        description: "[MAIL] #{mail.subject}", 
                        commentaires: "De #{mail.from_address} : #{mail.body}"
                      )
        # puts "#{intervention.inspect}"
        # puts "#{intervention.valid?}"
        intervention.save
        # puts 'après création intervention'
      end
    end
  end

end