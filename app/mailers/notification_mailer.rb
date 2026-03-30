class NotificationMailer < ApplicationMailer

  def workflow_changed(intervention, emails)
    @intervention = intervention

    mail(to: emails,
        bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
        subject: "[COOPCOMM] Changement de statut").tap do |message|
      message.mailgun_options = {
        "tag" => ["changement de statut"]
      }
    end
  end

  def commentaires_changed(intervention, emails)
    @intervention = intervention

    mail(to: emails,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOMM] Nouveau commentaire").tap do |message|
      message.mailgun_options = {
        "tag" => ["nouveau commentaire"]
      }
    end
  end

  def relance(intervention)
    @intervention = intervention

    mail(to: intervention.adherent.email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOMM] Relance. Intervention à valider").tap do |message|
      message.mailgun_options = {
        "tag" => ["relance"]
      }
    end
  end

  def intervention_pointage(intervention)
    @intervention = intervention

    mail(to: intervention.adherent.email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu',
          subject: "[COOPCOMM] Pointage").tap do |message|
      message.mailgun_options = {
        "tag" => ["pointage"]
      }
    end
  end

  def welcome(user)
    @user = user
    mail(to: @user.email, subject: '[COOPCOMM] Bienvenue !')
  end

  def new_organisation(organisation)
    @organisation = organisation
    mail(to: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu', subject: '[COOPCOMM] Nouvelle Organisation')
  end

  def confirm_email_newsletter(email)
    mail(to: email,
          bcc: 'philippe.nougaillon@aikku.eu, pierre-emmanuel.dacquet@aikku.eu, sebastien.pourchaire@aikku.eu, alexandre.meunier@aikku.eu',
          subject: '[COOPCOMM] Confirmation de l\'inscription pour la newsletter')
  end

  def welcome_import(user, title, password)
    @user = user
    @password = password
    mail(to: @user.email, subject: title)
  end

  def new_absence(absence, user_email)
    @absence = absence
    mail(to: user_email, subject: '[COOPCOMM] Nouvelle absence')
  end

  def new_intervention_from_adherent(intervention, user_email, title)
    @intervention = intervention
    mail(to: user_email, subject: title)
  end

  def intervention_done_by_agent(intervention, user_email, title)
    @intervention = intervention
    mail(to: user_email, subject: title)
  end

  def avertissement_reservation(user, tool, date_reservation, date_panne, title)
    @user = user
    @tool = tool
    @date_reservation = date_reservation
    @date_panne = date_panne

    mail(
      to: @user.email, 
      subject: title
    )
  end
end
