# frozen_string_literal: true

module InterventionsHelper
  # Destination du bouton « Terminer », sous la forme [lien, méthode HTTP, paramètres].
  # Les paramètres passent par des champs cachés : un formulaire GET perd la query string de son action.
  def terminer_destination(intervention)
    return [pointer_intervention_path(intervention.intervention_mère), :get, nil] if intervention.pointage_de?(current_user)

    if intervention.début.blank? || intervention.fin.blank?
      return [edit_intervention_path(intervention), :get, { terminer: 1 }]
    end

    [terminer_intervention_path(intervention), :post, nil]
  end
end
