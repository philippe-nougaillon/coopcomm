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
    if (modèle = modèle_à_pointer(intervention))
      return [pointer_intervention_path(modèle), :get, nil]
    end

    if champs_manquants_pour_terminer(intervention).any?
      return [edit_intervention_path(intervention), :get, { terminer: 1 }]
    end

    [terminer_intervention_path(intervention), :post, nil]
  end

  # Nil si le bouton ne doit pas passer par `pointer` — y compris quand le slug du
  # modèle est obsolète, auquel cas il n'y a aucune cible à pointer.
  def modèle_à_pointer(intervention)
    return nil unless intervention.pointage_du_jour_de?(current_user)

    intervention.intervention_mère
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
    return nil if champs.empty? || modèle_à_pointer(intervention)

    "#{champs.to_sentence.upcase_first} #{champs.one? ? 'est obligatoire' : 'sont obligatoires'} pour terminer cette intervention."
  end


  # --- Boutons de workflow ---

  STYLES_LISTE = {
    terminer: 'z-10 btn btn-primary border border-gray-200 btn-outline btn-base hover:text-white!',
    valider: 'z-10 btn btn-success border border-gray-200 btn-outline btn-base hover:text-white!',
    refuser: 'z-10 btn btn-error border border-gray-200 btn-outline btn-base hover:text-white!'
  }.freeze

  TITRES_LISTE = {
    terminer_modal: "Terminer l'intervention",
    terminer: "Cliquez pour passer cette intervention en statut 'Terminé'",
    valider: "Cliquez pour passer cette intervention en statut 'Validé'",
    refuser: "Cliquez pour passer cette intervention en statut 'Refusé'"
  }.freeze

  # Vrai si au moins un bouton de transition sera rendu, la page d'une
  # intervention masquant — contrairement à la liste — ce qui n'est pas
  # déclenchable.
  def actions_workflow_disponibles?(intervention)
    (policy(intervention).terminer? && intervention.can_terminer?) ||
      (policy(intervention).valider? && intervention.can_valider?) ||
      (policy(intervention).refuser? && intervention.can_refuser?)
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

  # Le compte-rendu est saisissable une fois l'intervention réalisée, ou par
  # anticipation quand on vient du bouton « Terminer ». Il dépend donc de la
  # requête en cours, ce qui le distingue des prédicats de la policy.
  #
  # Défini par EXCLUSION : un état ajouté au workflow aura le compte-rendu par
  # défaut, comme `terminé`, `validé`, `refusé` et `archivé`.
  ETATS_SANS_COMPTE_RENDU = [Intervention::NOUVEAU, Intervention::POINTAGE_ACTIVE].freeze

  def saisir_compte_rendu?(intervention, terminaison_demandee)
    return false if intervention.repeter? || current_user.agent?

    # `current_state` et non `workflow_state` : la colonne est nil sur une
    # intervention neuve, et nil ne figure dans aucune liste d'exclusion.
    ETATS_SANS_COMPTE_RENDU.exclude?(intervention.current_state.to_s) ||
      (intervention.nouveau? && terminaison_demandee)
  end
end