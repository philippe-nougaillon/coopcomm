# frozen_string_literal: true

namespace :interventions do
  desc 'Relancer par email'
  task :relancer, [:enregistrer] => :environment do |_task, _args|
    interventions = Intervention.with_terminé_state.where('updated_at::DATE - NOW()::DATE >= ?', 3)

    interventions.each do |intervention|
      next unless intervention.adherent

      # TODO: à mettre dans un job
      mailer_response = NotificationMailer.relance(intervention).deliver_now
      MailLog.create(organisation_id: intervention.organisation_id, user_id: 0,
                     message_id: mailer_response.message_id, to: intervention.adherent.email, subject: 'Relance : intervention terminée', channel: 0)
      intervention.update!(audit_comment: "Adhérent relancé par mail pour la validation de l'intervention")
      # puts "-- Traitement terminé --"
      # puts "'#{intervention.description}' traitée"
    end
  end

  desc 'Clôturer automatiquement les pointages non terminés (état « nouveau » avec une date de début) — à lancer tous les jours à 22h'
  task :terminer_pointages, [:enregistrer] => :environment do |_task, _args|
    interventions = Intervention.with_nouveau_state
                                .where.not(template_slug: [nil, ''])
                                .where.not(début: nil)

    interventions.find_each do |intervention|
      agent = intervention.agents.first

      intervention.fin = Time.current
      # crashera si l'intervention est invalide (ex: conflit agent)
      intervention.terminer!

      next unless agent

      mailer_response = NotificationMailer.intervention_pointage_terminee_automatiquement(intervention, agent.email).deliver_now
      MailLog.create(organisation_id: intervention.organisation.id, user_id: 0,
                     message_id: mailer_response.message_id, to: agent.email, subject: 'Pointage terminé automatiquement', channel: 0)
    rescue StandardError => e
      # Un enregistrement en échec ne doit pas interrompre tout le batch quotidien.
      Rails.logger.error("[interventions:terminer_pointages] échec sur l'intervention ##{intervention.id} : #{e.message}")
    end
  end



  # desc "Notifier un manager quand un agent n'a pas pointé de sortie"
  # task :report_missed_clock_out, [:enregistrer] => :environment do |_task, _args|
  #   # Récupération des interventions filles sans date de fin, dont le début a commencé il y a plus de 10h
  #   interventions_missed = Intervention.where.not(template_slug: nil).where(fin: nil).where('début < ?',
  #                                                                                           10.hours.ago)

  #   interventions_missed.each do |intervention|
  #     # Manager qui gère le service de l'intervention
  #     manager = intervention.intervention_mère&.audits&.find_by(action: 'create')&.user
  #     next unless manager

  #     mailer_response = NotificationMailer.report_missed_clock_out(intervention, manager.email).deliver_now
  #     MailLog.create(organisation_id: intervention.organisation_id, user_id: 0,
  #                    message_id: mailer_response.message_id, to: manager.email, subject: "Rappel d'une intervention non terminée", channel: 0)
  #   end
  # end
end
