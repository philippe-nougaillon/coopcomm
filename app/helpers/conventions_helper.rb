# frozen_string_literal: true

module ConventionsHelper
  # Calcule l'avancement d'une convention dans le temps (aujourd'hui par rapport
  # à date_début / date_fin_prévue) pour alimenter une barre de progression daisyUI.
  def convention_progress(convention, today: Date.current)
    start_date = convention.date_début
    end_date = convention.date_fin_prévue
    

    total   = (end_date - start_date).to_i
    elapsed = (today - start_date).to_i

    percent =
      if total <= 0
        today >= end_date ? 100 : 0
      else
        ((elapsed.to_f / total) * 100).round.clamp(0, 100)
      end

    color, label =
      if today < start_date
        ['progress-info', 'À venir']
      elsif today > end_date
        ['progress-error', 'Expirée']
      elsif percent >= 80
        ['progress-warning', "#{percent} %"]
      else
        ['progress-success', "#{percent} %"]
      end

    # On évite la division par zéro si heures_conventionnees est nil ou égal à zéro.
    heures = convention.heures_conventionnees.to_f
    indicateur = heures.positive? ? (convention.temps_total_interventions / heures * 100).round(1) : 0


    # L'indicateur devient rouge si le temps total dans les interventions dépasse le nombre d'heures conventionnées.
    if indicateur > 100
      indicateur_label = "Aujourd'hui : Durée dépassée de #{((convention.temps_total_interventions)-heures).round(1)}%"
      indicateur = 100
      indicateur_color = 'bg-error'
    else
      indicateur_label = "Aujourd'hui (Temps écoulé : #{indicateur.round(1)}%)"
      indicateur_color = 'bg-neutral'
    end

    { percent: percent, label: label, color: color,indeterminate: false, indicateur: indicateur, indicateur_label: indicateur_label, indicateur_color: indicateur_color }
  end
end
