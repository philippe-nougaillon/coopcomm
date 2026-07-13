# frozen_string_literal: true


module MouvementsHelper
  def field_label(key)
    {
      'entrée' => 'Entrée',
      'fin_panne' => 'Fin de la panne',
      'sortie' => 'Sortie',
      'panne' => 'Panne',
      'réservé' => 'Réservé'
    }.fetch(key.to_s.downcase, key.to_s.humanize) # .to_s.downcase añade un extra de seguridad
  end
end