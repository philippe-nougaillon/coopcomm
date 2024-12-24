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

end
