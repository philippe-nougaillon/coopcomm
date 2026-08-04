# frozen_string_literal: true

module InterventionsHelper
  # --- Destination du bouton « Terminer » ---

  def modal_id_terminer(intervention)
    "terminer_modal_#{intervention.id}"
  end

  def js_ouvrir_modal_terminer(intervention)
    "document.getElementById('#{modal_id_terminer(intervention)}').showModal()"
  end

  # Destination du bouton « Terminer », sous la forme [lien, méthode HTTP, paramètres].
  # Les paramètres passent par des champs cachés : un formulaire GET perd la query string de son action.
  def terminer_destination(intervention)
    return [pointer_intervention_path(intervention.intervention_mère), :get, nil] if intervention.pointage_de?(current_user)

    if champs_manquants_pour_terminer(intervention).any?
      return [edit_intervention_path(intervention, terminer: 1), :get, nil] 
    end

    [terminer_intervention_path(intervention), :post, nil]
  end

  def champs_manquants_pour_terminer(intervention)
    champs = []
    champs << 'la date de début' if intervention.début.blank?
    champs << 'la date de fin' if intervention.fin.blank?
    champs << 'le temps de pause' if intervention.temps_de_pause.blank?
    champs << 'au moins un agent' if intervention.agents.empty?
    champs
  end

  def message_terminaison_incomplete(intervention)
    champs = champs_manquants_pour_terminer(intervention)
    return nil if champs.empty?

    "#{champs.to_sentence.upcase_first} #{champs.one? ? 'est obligatoire' : 'sont obligatoires'} pour terminer cette intervention."
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