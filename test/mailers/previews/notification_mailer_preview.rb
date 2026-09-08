# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def workflow_changed
    NotificationMailer.workflow_changed(Intervention.last, User.last.email)
  end

  def relance
    NotificationMailer.relance(Intervention.first)
  end

  def intervention_pointage
    NotificationMailer.intervention_pointage(Intervention.last)
  end

  def confirm_email_newsletter
    NotificationMailer.confirm_email_newsletter(User.last.email)
  end

  def welcome_import
    NotificationMailer.welcome_import(User.last, '[CoopComm] Bienvenue !', SecureRandom.base64(12))
  end

  def new_absence
    NotificationMailer.new_absence(Absence.last, User.last)
  end

  def new_intervention_from_adherent
    NotificationMailer.new_intervention_from_adherent(Intervention.last, User.last.email,
                                                      'Nouvelle intervention adhérent')
  end

  def intervention_done_by_agent
    NotificationMailer.new_intervention_from_adherent(Intervention.last, User.last.email,
                                                      "Nouveau bon d'intervention d'un agent")
  end

  def avertissement_reservation
    réservation = Mouvement.last(2).first
    panne = Mouvement.last
    title = "[COOPCOMM] L'outil #{panne.tool.name} a été déclaré en panne"
    NotificationMailer.avertissement_reservation(réservation.user, panne.tool, réservation.date, panne.date, title)
  end

  def intervention_pointage_terminee_automatiquement
    NotificationMailer.intervention_pointage_terminee_automatiquement(Intervention.last, User.last.email)
  end
end
