# frozen_string_literal: true

class SetDefaultRepeterFalseOnInterventions < ActiveRecord::Migration[8.0]
  # Contexte : la colonne `repeter` a été ajoutée sans `default`. Tant que le
  # formulaire d'intervention contenait `form.check_box :repeter`, le champ caché
  # de la case envoyait toujours `0` → `false`. Le commit #267 a retiré cette
  # case : les interventions créées depuis arrivent avec `repeter = NULL`, et
  # sont alors exclues du calcul des notes d'agent (`where(repeter: false)` ne
  # matche pas NULL). Voir User#moyenne / #star_count / #total_rating.
  def up
    # 1. Backfill : les interventions sans valeur explicite valent `false`
    #    (comportement historique de la case décochée).
    execute 'UPDATE interventions SET repeter = false WHERE repeter IS NULL'

    # 2. Les futures interventions héritent de `false` même si le formulaire
    #    n'envoie pas le champ.
    change_column_default :interventions, :repeter, from: nil, to: false
  end

  def down
    change_column_default :interventions, :repeter, from: false, to: nil
    # Pas de restauration des NULL : on ne peut pas distinguer les `false`
    # d'origine des lignes backfillées.
  end
end
