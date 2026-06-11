# frozen_string_literal: true

class UpdateMouvementsEtatEnum < ActiveRecord::Migration[8.0]
  def up
    # 1. On supprime les états obsolètes : achat (0), réforme (1), révision (4)
    # On utilise delete_all pour exécuter un DELETE SQL direct sans instancier le modèle.
    Mouvement.where('état IN (0, 1, 4)').delete_all

    # 2. On réassigne les valeurs conservées.
    # L'ordre est TRÈS important ici pour éviter les collisions (écraser des données) :

    # Étape A : L'entrée (2) prend la place libre de l'achat (0)
    Mouvement.where('état = 2').update_all('état = 0')

    # Étape B : La sortie (3) prend la place libre de la réforme (1)
    Mouvement.where('état = 3').update_all('état = 1')

    # Étape C : La panne (5) prend la place libre que l'entrée vient de libérer (2)
    Mouvement.where('état = 5').update_all('état = 2')
  end

  def down
    # Le chemin inverse exact au cas où tu ferais un rails db:rollback
    Mouvement.where('état = 2').update_all('état = 5') # panne : 2 -> 5
    Mouvement.where('état = 1').update_all('état = 3') # sortie : 1 -> 3
    Mouvement.where('état = 0').update_all('état = 2') # entrée : 0 -> 2

    # NOTE: Les données supprimées (achat, réforme...) ne seront pas restaurées.
  end
end
