class UpdateEtatsFromMouvement < ActiveRecord::Migration[8.0]
  def change
    # Suppression des mouvements avec les anciens etats "entrée" (0) et "sortie" (1)
    Mouvement.where(état: [0, 1]).destroy_all

    # Etat "réservé", 4 -> 0
    Mouvement.where(état: 4).update_all(état: 0)

    # Etat "panne", 2 -> 1
    Mouvement.where(état: 2).update_all(état: 1)

    # Etat "fin_panne", 3 -> 2
    Mouvement.where(état: 3).update_all(état: 2)
  end
end
