# frozen_string_literal: true

module InterventionsHelper
  # Destination du bouton « Terminer » d'une intervention, sous la forme
  # [lien, méthode HTTP].
  #
  # Pour un agent sur une intervention issue d'un pointage (`template_slug`
  # renseigné), on repasse par l'action `pointer` de l'intervention modèle,
  # comme sur la page d'accueil : elle enregistre la fin réelle, recalcule le
  # temps passé et redirige vers le statut de pointage, là où l'action
  # `terminer` se contente de changer l'état (fin et temps non renseignés).
  #
  # Repli sur `terminer` si l'intervention modèle est introuvable (slug
  # obsolète), pour ne pas générer de lien vers nil.
  def terminer_destination(intervention)
    modèle = intervention.intervention_mère if current_user&.agent? && intervention.template_slug.present?

    return [pointer_intervention_path(modèle), :get] if modèle

    [terminer_intervention_path(intervention), :post]
  end
end
