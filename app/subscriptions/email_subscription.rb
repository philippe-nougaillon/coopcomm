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
    user = User.find(intervention.audits.last.user_id)
    return unless user.agent? && intervention.adherent

    if (adherent = User.find_by(id: intervention.adherent_id))
      NotifAdherentInterventionTermineeJob.perform_later(intervention, adherent, user.id)
    end
  end

  # Notifier les agents qu'un commentaire a été ajouté par l'adhérent
  def on_intervention_updated(event)
    # Déclaration des variables pour tester si on doit lancer le job
    intervention = Intervention.find(event[:payload][:intervention_id])
    last_audit = intervention.audits.last
    user = User.find(last_audit.user_id)
    is_commentaires_changed = last_audit.audited_changes.include?('commentaires')

    # Vérifie si on doit lancer le job
    should_notify_agents = user.adhérent? && is_commentaires_changed && !intervention.commentaires.blank?

    return unless should_notify_agents

    agent_ids = intervention.agents.pluck(:id)
    NotifAgentsCommentairesChangedJob.perform_later(intervention, agent_ids, user.id) if agent_ids.any?
  end

  def on_intervention_pointage(event)
    intervention = Intervention.find(event[:payload][:intervention_id])

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
