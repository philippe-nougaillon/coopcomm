class EmailSubscription

  # Notifier les managers qu'un changement de statut a eu lieu
  def on_intervention_workflow_changed(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user_id = intervention.audits.last.user_id
    managers = intervention.organisation.users.where.not(id: user_id).manager
    if managers.any?
      NotifManagersWorkflowChangedJob.perform_later(intervention, managers.pluck(:email), user_id)
      managers.each do |manager|
        Notification.create!(message:"Une intervention a changé de statut", user_id: manager.id)
      end
    end
  end

  # Notifier les adhérents qu'une intervention a été terminée par un agent
  def on_intervention_done(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    user = User.find(intervention.audits.last.user_id)
    if user.agent? && intervention.adherent
      adherents = User.where(id: intervention.adherent_id)
      if adherents.any?
        NotifAdherentInterventionTermineeJob.perform_later(intervention, adherents.pluck(:email), user.id)
        adherents.each do |adherent|
          Notification.create!(message:"Un agent a terminé une intervention", user_id: adherent.id)
        end
      end
    end
  end

  # Notifier les agents qu'un commentaire a été ajouté par un adhérent
  def on_intervention_updated(event)
    intervention = Intervention.find(event[:payload][:intervention_id])
    last_audit = intervention.audits.last
    user = User.find(last_audit.user_id)
    commentaires_changed = last_audit.audited_changes.include?('commentaires')
    send_notif = (user.adhérent? && commentaires_changed && !intervention.commentaires.blank?)
    agents = User.where(id: [intervention.agent.try(:id), intervention.agent_binome.try(:id)])
    if send_notif && agents.any?
      NotifAgentsCommentairesChangedJob.perform_later(intervention, agents.pluck(:email), user.id)
      agents.each do |agent|
        Notification.create!(message:"Un adhérent a ajouté un commentaire", user_id: agent.id)
      end
    end
  end

  def on_organisation_created(event)
    user = User.find(event[:payload][:user_id])
    WelcomeNotificationJob.perform_later(user)
    NewOrganisationNotificationJob.perform_later(user.organisation)
  end

end