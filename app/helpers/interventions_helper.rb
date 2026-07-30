# frozen_string_literal: true

module InterventionsHelper
  # --- Destination du bouton « Terminer » ---
  
  # Destination du bouton « Terminer », sous la forme [lien, méthode HTTP, paramètres].
  # Les paramètres passent par des champs cachés : un formulaire GET perd la query string de son action.
  def terminer_destination(intervention)
    return [pointer_intervention_path(intervention.intervention_mère), :get, nil] if intervention.pointage_de?(current_user)

    if intervention.début.blank? || intervention.fin.blank?
      return [edit_intervention_path(intervention), :get, { terminer: 1 }]
    end

    [terminer_intervention_path(intervention), :post, nil]
  end

  # --- Trajet ---

  def trajet_affichable?(intervention)
    intervention.service&.calculate_distance?
  end

  def trajet_mode(intervention, routes_response)
    if intervention.nouveau? && routes_response.present? && routes_response.dig('data_response').present?
      :mapa
    elsif intervention.trajet.presence || routes_response&.dig('routes_info').presence
      :texte
    else
      :vide
    end
  end

  def trajet_texte(intervention, routes_response)
    intervention.trajet.presence || routes_response&.dig('routes_info').presence
  end

  # --- Compte-rendu ---

  ETATS_SANS_COMPTE_RENDU = [Intervention::NOUVEAU, Intervention::POINTAGE_ACTIVE].freeze

  def peut_voir_compte_rendu?(intervention, user)
    return false unless user.adhérent? || user.manager_or_admin?

    ETATS_SANS_COMPTE_RENDU.exclude?(intervention.workflow_state)
  end

  def compte_rendu_est_avis?(intervention, user)
    (intervention.validé? || intervention.refusé?) && !user.agent?
  end
end