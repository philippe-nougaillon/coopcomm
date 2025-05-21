class NotificationMailer < ApplicationMailer

  def workflow_changed(intervention, emails)
    @intervention = intervention

    mail(to: emails,
        bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
        subject: "[COOPCOM] Changement de statut").tap do |message|
      message.mailgun_options = {
        "tag" => ["changement de statut"]
      }
    end
  end

  def commentaires_changed(intervention, emails)
    @intervention = intervention

    mail(to: emails,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOM] Nouveau commentaire").tap do |message|
      message.mailgun_options = {
        "tag" => ["nouveau commentaire"]
      }
    end
  end

  def relance(intervention)
    @intervention = intervention

    mail(to: intervention.adherent.email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOM] Relance. Intervention à valider").tap do |message|
      message.mailgun_options = {
        "tag" => ["relance"]
      }
    end
  end

  def intervention_pointage(intervention)
    @intervention = intervention

    mail(to: intervention.adherent.email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOM] Pointage").tap do |message|
      message.mailgun_options = {
        "tag" => ["pointage"]
      }
    end
  end

  def welcome(user)
    @user = user
    mail(to: @user.email, subject: '[COOPCOM] Bienvenue !')
  end

  def new_organisation(organisation)
    @organisation = organisation
    mail(to: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu', subject: '[COOPCOM] Nouvelle Organisation')
  end

  def confirm_email_newsletter(email)
    mail(to: email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu, alexandre.meunier@aikku.eu',
          subject: '[COOPCOM] Confirmation de l\'inscription pour la newsletter')
  end
end
