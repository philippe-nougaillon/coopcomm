# frozen_string_literal: true

# Lancée par l'analyse qui a réveillé l'IA, et seulement par elle : tant qu'elle tourne, c'est CoopComm qui a allumé
# l'IA. Elle la remet en pause dès qu'aucune analyse n'attend plus, une fois son démarrage fini.
class SurveillerIaJob < ApplicationJob
  queue_as :default
  retry_on InstanceIa::Erreur, wait: 1.minute, attempts: 10

  CADENCE = 1.minute

  def perform
    return self.class.set(wait: CADENCE).perform_later if Convention.en_analyse.exists?(updated_at: AnalyserConventionJob::ABANDON.ago..)

    etat = InstanceIa.etat
    return if (InstanceIa::EN_PAUSE + InstanceIa::MISE_EN_PAUSE).include?(etat)
    return self.class.set(wait: CADENCE).perform_later if InstanceIa::REVEIL.include?(etat)

    InstanceIa.mettre_en_pause
    AnnoncerEtatIa.call('SHELVING')
  end
end
