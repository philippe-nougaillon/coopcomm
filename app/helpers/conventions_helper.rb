# frozen_string_literal: true

module ConventionsHelper
  # TODO : Modifier la fonction qui n'est plus adaptée dans la vue _convention.html.erb
  # Calcule l'avancement d'une convention dans le temps (aujourd'hui par rapport
  # à date_début / date_fin_prévue) pour alimenter une barre de progression daisyUI.
  # Renvoie nil si aucune date de début (rien à afficher), sinon un hash :
  #   { percent:, color:, label:, indeterminate: }
  # - indeterminate: true  → convention sans échéance (barre animée « En cours »)
  def convention_progress(convention, today: Date.current)
    start_date = convention.date_début
    return nil if start_date.blank?

    end_date = convention.date_fin_prévue

    # Pas d'échéance : convention active sans terme défini → barre indéterminée.
    return { percent: nil, color: 'progress-info', label: 'En cours', indeterminate: true } if end_date.blank?

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
        %w[progress-error Expirée]
      elsif percent >= 80
        ['progress-warning', "#{percent} %"]
      else
        ['progress-success', "#{percent} %"]
      end

      indicateur = convention.temps_total_interventions / convention.heures_conventionnees*100
      if indicateur > 100
        indicateur_label = "Dépassement de #{indicateur - 100} %"
        indicateur = 100
        indicateur_color = 'bg-error'
      else
        indicateur_label = "Indicateur : #{indicateur.round(1)} %"
        indicateur_color = 'bg-neutral'
      end

    { percent: percent, color: color, label: label, indeterminate: false, indicateur: indicateur, indicateur_label: indicateur_label, indicateur_color: indicateur_color }


  end


end
