# frozen_string_literal: true

module ConventionsHelper
  # Calcule l'avancement d'une convention dans l'année en cours (aujourd'hui par rapport
  # à la part de l'année qu'elle couvre) pour alimenter une barre de progression daisyUI.
  def convention_progress(convention, today: Date.current)
    start_date = [convention.date_début, today.beginning_of_year].max
    end_date = [convention.date_fin_prévue, today.end_of_year].compact.min
    

    total   = (end_date - start_date).to_i
    elapsed = (today - start_date).to_i

    percent =
      if total <= 0
        today >= start_date ? 100 : 0
      else
        ((elapsed.to_f / total) * 100).round.clamp(0, 100)
      end

    # On évite la division par zéro si heures_conventionnees est nil ou égal à zéro.
    heures = convention.heures_conventionnees.to_f
    depasse= convention.heures_consommees

    color, label =
      if today < start_date
        ['progress-info', 'À venir']
      elsif today > end_date
        ['progress-error', 'Expirée']
      elsif depasse.round(1) > heures
        ['progress-error', "#{percent} %"]
      elsif heures.positive? && depasse >= 1.1 * heures / 365 * (elapsed + 1)
        ['progress-warning', "#{percent} %"]
      else
        ['progress-success', "#{percent} %"]
      end

    indicateur = heures.positive? ? (convention.heures_consommees / heures * 100).round(1) : 0


    # L'indicateur devient rouge si le temps total dans les interventions dépasse le nombre d'heures conventionnées.
    if indicateur > 100
      depassement = depasse - heures
      indicateur_label = "Aujourd'hui : Durée dépassée de #{depassement.round(1)}h"
      indicateur = 100
      indicateur_color = 'bg-error'
    elsif indicateur < 0
      depassement = depasse
      indicateur_label = "Aujourd'hui : Durée inférieur de #{depassement.round(1)}h. Veuillez mettre à jour les interventions avec un temps total positif"
      indicateur = 0
      indicateur_color = 'bg-error'
    else
      depassement = 0
      indicateur_label = "Aujourd'hui (Temps écoulé : #{indicateur.round}%)"
      indicateur_color = 'bg-neutral'
    end

    { percent: percent, label: label, color: color,indeterminate: false, indicateur: indicateur, indicateur_label: indicateur_label, indicateur_color: indicateur_color, depassement: depassement }
  end
end
