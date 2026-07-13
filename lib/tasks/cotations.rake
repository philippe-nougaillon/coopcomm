# frozen_string_literal: true

namespace :cotations do
  # Planifiée côté Hatchbox (pas de recurring.yml). Peut tourner à n'importe
  # quelle fréquence (ex. 1×/jour) : la garde des 48h ci-dessous évite les
  # doublons et rattrape une exécution manquée.
  desc 'Relancer par email les adhérents ayant des cotations à signer (état « envoyé »), au plus toutes les 48h'
  task :relancer_adherents, [:enregistrer] => :environment do |_task, _args|
    a_signer = Cotation.kept.where(workflow_state: Cotation::ENVOYE).includes(:adherent)

    a_signer.group_by(&:adherent).each_key do |adherent|
      next if adherent.nil? || adherent.email.blank?

      # « 48h après le dernier mail » : on prend le dernier mail lié à une
      # cotation adressé à cet adhérent — cela couvre aussi bien l'envoi
      # initial (cotation_envoyee, qui pose cotation_id) que les relances
      # précédentes. On ne relance que si ce délai est écoulé (ou jamais reçu).
      last_cotation_mail_at = MailLog.where(to: adherent.email)
                                     .where.not(cotation_id: nil)
                                     .maximum(:created_at)
      next if last_cotation_mail_at.present? && last_cotation_mail_at > 48.hours.ago

      NotifAdherentCotationsASignerRelanceJob.perform_later(adherent)
    end
  end
end
