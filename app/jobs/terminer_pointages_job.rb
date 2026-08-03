# frozen_string_literal: true

class TerminerPointagesJob < ApplicationJob
  queue_as :default

  def perform
    interventions = Intervention.with_nouveau_state
                                .where.not(template_slug: [nil, ''])
                                .where.not(début: nil)

    interventions.find_each do |intervention|
      terminer_pointage(intervention)
    rescue StandardError => e
      # Un enregistrement en échec ne doit pas interrompre tout le batch quotidien.
      Rails.logger.error("[TerminerPointagesJob] échec sur l'intervention ##{intervention.id} : #{e.message}")
    end
  end

  private

  def terminer_pointage(intervention)
    agent = intervention.agents.first

    intervention.fin = Time.current
    intervention.sans_notification = true
    intervention.terminer!

    # Quand il y a un template_slug, l'intervention n'a toujours qu'un seul agent.
    return unless agent

    mailer_response = NotificationMailer.intervention_pointage_terminee_automatiquement(intervention, agent.email).deliver_now
    MailLog.create(organisation_id: intervention.organisation.id, user_id: 0,
                   message_id: mailer_response.message_id, to: agent.email, subject: 'Pointage terminé automatiquement', channel: 0)
  end
end
