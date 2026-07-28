# frozen_string_literal: true

module InterventionsHelper
  # Destination du bouton « Terminer », sous la forme [lien, méthode HTTP].
  def terminer_destination(intervention)
    return [pointer_intervention_path(intervention.intervention_mère), :get] if intervention.pointage_de?(current_user)

    [terminer_intervention_path(intervention), :post]
  end
end
