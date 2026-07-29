# frozen_string_literal: true

namespace :cotations do
  # Planifiée côté Hatchbox. La garde des 48h évite les doublons et rattrape
  # une exécution manquée, quelle que soit la fréquence.
  desc 'Relancer par email les adhérents ayant des cotations à signer (état « envoyé »), au plus toutes les 48h'
  task :relancer_adherents, [:enregistrer] => :environment do |_task, _args|
    a_signer = Cotation.kept.where(workflow_state: Cotation::ENVOYE).includes(:adherent)

    a_signer.group_by(&:adherent).each_key do |adherent|
      next if adherent.nil? || adherent.email.blank?

      # Dernier mail lié à une cotation : couvre l'envoi initial comme les relances.
      last_cotation_mail_at = MailLog.where(to: adherent.email)
                                     .where.not(cotation_id: nil)
                                     .maximum(:created_at)
      next if last_cotation_mail_at.present? && last_cotation_mail_at > 48.hours.ago

      NotifAdherentCotationsASignerRelanceJob.perform_later(adherent)
    end
  end
end
