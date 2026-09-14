# frozen_string_literal: true

# Tri des tableaux, CÔTÉ CONTRÔLEUR : lit et valide `params[:column]` et
# `params[:direction]`, porte le tri par défaut de la page, applique le `reorder`,
# et expose `sort_column` / `sort_direction` / `colonne_triable?` aux vues d'index,
# où `th_tri` s'en sert pour rendre les en-têtes cliquables.
#
# Les colonnes triables sont déclarées dans le modèle
# (`ColonnesTriables`) ; le contrôleur ne dit que ce que la page en fait :
#
#   trie User, defaut: 'users.nom'      # une ligne par tableau affiché
#   …
#   @users = trier(@users)              # le modèle est déduit de la relation
#
# Pour un modèle qui ne nous appartient pas (audits), les colonnes se passent en
# argument.
module Triable
  extend ActiveSupport::Concern

  SENS = %w[asc desc].freeze

  # Une expression n'est éprouvée qu'une fois par processus : sa validité ne
  # dépend que du schéma.
  ORDRES_ÉPROUVÉS = Concurrent::Map.new

  included do
    class_attribute :tris, default: {}, instance_writer: false
    helper_method :sort_column, :sort_direction, :colonne_triable?
  end

  class_methods do
    def trie(modele, colonnes = nil, defaut:, sens: :asc, puis: nil)
      puis ||= modele.tri_secondaire if modele.respond_to?(:tri_secondaire)
      self.tris = tris.merge(
        modele.name => { colonnes: (colonnes || modele.colonnes_triables).transform_keys(&:to_s),
                         defaut: defaut.to_s, sens: sens.to_s, puis: puis }
      )
    end
  end

  def sort_column
    colonne_triable?(params[:column]) ? params[:column] : nil
  end

  def sort_direction
    SENS.include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def colonne_triable?(colonne)
    colonne.present? && tris.values.any? { |tri| tri[:colonnes].key?(colonne) }
  end

  def trier(relation)
    tri = tris.fetch(relation.klass.name)
    colonne, sens = colonne_et_sens(tri)
    expressions = expressions_utilisables(relation, tri, colonne)

    relation = TriTextuel.exposer(relation, expressions)
    relation.reorder(Arel.sql(clause_order(expressions, sens.upcase, relation.klass)))
  end

  private

  # Une colonne renommée en base rendrait l'expression déclarée invalide : on
  # l'éprouve sur zéro ligne avant de l'appliquer, et on retombe sur le tri par
  # défaut — puis sur la clé primaire — plutôt que de rendre une page en erreur.
  def expressions_utilisables(relation, tri, colonne)
    demandées = [expression_sql(tri, colonne), tri[:puis]].compact_blank
    return demandées if ordre_valide?(relation, demandées)

    défaut = [expression_sql(tri, tri[:defaut]), tri[:puis]].compact_blank
    return défaut if colonne != tri[:defaut] && ordre_valide?(relation, défaut)

    []
  end

  def ordre_valide?(relation, expressions)
    return true if expressions.empty?

    clé = [relation.klass.name, expressions]
    validité = ORDRES_ÉPROUVÉS[clé]
    return validité unless validité.nil?

    ORDRES_ÉPROUVÉS[clé] = ordre_accepté_par_la_base?(relation, expressions)
  end

  # Point de sauvegarde obligatoire : une requête refusée annule la transaction
  # en cours sous Postgres, et le tri peut être demandé depuis l'intérieur d'une.
  def ordre_accepté_par_la_base?(relation, expressions)
    ActiveRecord::Base.transaction(requires_new: true) do
      TriTextuel.exposer(relation, expressions)
                .reorder(Arel.sql(clause_order(expressions, 'ASC', relation.klass)))
                .where('1 = 0')
                .limit(1)
                .load
    end
    true
  rescue ActiveRecord::StatementInvalid => e
    Rails.logger.error("Tri inapplicable, repli sur le tri par défaut (#{expressions.join(', ')}) : #{e.message}")
    false
  end

  def colonne_et_sens(tri)
    if tri[:colonnes].key?(sort_column)
      [sort_column, sort_direction]
    else
      [tri[:defaut], tri[:sens]]
    end
  end

  def clause_order(expressions, sens, klass)
    morceaux = expressions.map { |expression| "#{expression} #{sens} NULLS LAST" }
    morceaux << "#{klass.quoted_table_name}.#{klass.primary_key} #{sens}"
    morceaux.join(', ')
  end

  def expression_sql(tri, colonne)
    case tri[:colonnes][colonne]
    when :texte then TriTextuel.expression(colonne)
    when :brut  then colonne
    else tri[:colonnes][colonne]
    end
  end
end
