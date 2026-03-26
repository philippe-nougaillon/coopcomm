# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview

  def commentaires_changed
    NotificationMailer.commentaires_changed(Intervention.last, User.last.email)
  end

  def workflow_changed
    NotificationMailer.workflow_changed(Intervention.last, User.last.email)
  end

  def relance
    NotificationMailer.relance(Intervention.first)
  end

  def welcome
    NotificationMailer.welcome(User.last)
  end

  def intervention_pointage
    NotificationMailer.intervention_pointage(Intervention.last)
  end

  def confirm_email_newsletter
    NotificationMailer.confirm_email_newsletter(User.last.email)
  end

  def new_absence
    NotificationMailer.new_absence(Absence.last, User.last)
  end

  def new_intervention_from_adherent
    NotificationMailer.new_intervention_from_adherent(Intervention.last, User.last.email, "Nouvelle intervention adhérent")
  end

  def avertissement_reservation
    réservation = Mouvement.last(2).first
    panne = Mouvement.last
    title = "[COOPCOMM] L'outil #{panne.tool.name} a été déclaré en panne"
    NotificationMailer.avertissement_reservation(réservation.user, panne.tool, réservation.date, panne.date, title)
  end

end
