# frozen_string_literal: true

class EmailSubscription
  # Notifier les managers qu'un changement de statut a eu lieu
  def on_intervention_workflow_changed(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user_id = intervention.audits.last.user_id
    manager_ids = intervention.service.managers.where.not(id: user_id).ids
    NotifManagersWorkflowChangedJob.perform_later(intervention, manager_ids, user_id) if manager_ids.any?
  end

  # Notifier l'adhérent qu'une intervention a été terminée par un agent
  def on_intervention_done(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user = User.find_by(id: intervention.audits.last&.user_id)
    # le dernier audit peut être le système qui termine l'intervention via "terminer_pointages"
    return unless user&.agent? && intervention.adherent

    if (adherent = User.find_by(id: intervention.adherent_id))
      NotifAdherentInterventionTermineeJob.perform_later(intervention, adherent, user.id)
    end
  end

  def on_intervention_pointage(event)
    # Un pointage dont le save a échoué publie un intervention_id nil : on ne
    # plante pas toute la requête web (find(nil) → RecordNotFound → 404) pour
    # une notification.
    intervention = Intervention.find_by(id: event[:payload][:intervention_id])
    return unless intervention

    NotifMailAdherentInterventionPointageJob.perform_later(intervention)

    # Envoyer un message WhatsApp
    NotifWhatsappAdherentInterventionPointageJob.perform_later(intervention) if intervention.adherent&.téléphone?
  end

  def on_organisation_created(event)
    user = User.find(event[:payload][:user_id])
    WelcomeNotificationJob.perform_later(user)
    NewOrganisationNotificationJob.perform_later(user.organisation)
  end

  def on_create_newsletter(event)
    email = Newsletter.find(event[:payload][:newsletter_id]).email
    NotifConfirmEmailNewsletterJob.perform_later(email)
  end
end
