class EmailSubscription

  # Notifier les managers qu'un changement de statut a eu lieu
  def on_intervention_workflow_changed(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user_id = intervention.audits.last.user_id
    manager_ids = intervention.organisation.users.where.not(id: user_id).manager.pluck(:id)
    if manager_ids.any?
      NotifManagersWorkflowChangedJob.perform_later(intervention, manager_ids, user_id)
    end
  end

  # Notifier l'adhérent qu'une intervention a été terminée par un agent
  def on_intervention_done(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user = User.find(intervention.audits.last.user_id)
    if (user.équipe? || user.agent?) && intervention.adherent
      if adherent = User.find_by(id: intervention.adherent_id)
        NotifAdherentInterventionTermineeJob.perform_later(intervention, adherent, user.id)
      end
    end
  end

  # Notifier les agents qu'un commentaire a été ajouté par l'adhérent
  def on_intervention_updated(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    last_audit = intervention.audits.last
    user = User.find(last_audit.user_id)
    commentaires_changed = last_audit.audited_changes.include?('commentaires')
    send_notif = (user.adhérent? && commentaires_changed && !intervention.commentaires.blank?)
    agent_ids = User.where(id: [intervention.agent.try(:id), intervention.agent_binome.try(:id)]).pluck(:id)
    if send_notif && agent_ids.any?
      NotifAgentsCommentairesChangedJob.perform_later(intervention, agent_ids, user.id)
    end
  end

  def on_organisation_created(event)
    user = User.find(event[:payload][:user_id])
    WelcomeNotificationJob.perform_later(user)
    NewOrganisationNotificationJob.perform_later(user.organisation)
  end

end