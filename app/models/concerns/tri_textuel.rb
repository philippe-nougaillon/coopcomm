# frozen_string_literal: true

# Source unique du « tri sans accent ni majuscule », côté SQL comme côté Ruby.
# Consommé par les scopes `ordered` des modèles, par les colonnes `:texte` de
# `ColonnesTriables` et par `Triable` au moment d'appliquer le tri ; les listes
# déroulantes des vues passent par `ranger`. Ne lit aucun paramètre de requête
# et ne décide d'aucun ordre : il ne fait que normaliser.
module TriTextuel
  extend ActiveSupport::Concern

  def self.expression(colonne)
    "LOWER(unaccent(#{colonne}::text))"
  end

  # Pendant Ruby de `expression`, pour les listes qui ne viennent pas d'une
  # requête : options d'un menu déroulant, tri d'un tableau calculé.
  def self.clé_de_tri(valeur)
    I18n.transliterate(valeur.to_s).downcase
  end

  # Accepte des textes, ou des couples [libellé, valeur] comme les attend
  # `options_for_select` : c'est toujours le libellé qui est rangé.
  def self.ranger(textes)
    textes.sort_by { |texte| clé_de_tri(Array(texte).first) }
  end

  # Postgres refuse un ORDER BY calculé absent du SELECT dès que la requête est
  # DISTINCT : on l'expose sous un alias. Ailleurs on n'y touche pas, une colonne
  # calculée en trop casserait un `count`.
  def self.exposer(relation, expressions)
    return relation unless relation.distinct_value

    calculées = expressions.reject { |expression| expression.match?(/\A[\w".À-ÿ]+\z/) }
    return relation if calculées.empty?

    colonnes = relation.select_values.empty? ? ["#{relation.klass.quoted_table_name}.*"] : []
    colonnes += calculées.each_with_index.map { |expression, rang| "#{expression} AS tri_#{rang}" }

    relation.select(*colonnes)
  end

  class_methods do
    def trié_par(*colonnes)
      expressions = colonnes.map { |colonne| TriTextuel.expression(colonne_qualifiée(colonne)) }

      TriTextuel.exposer(all, expressions).order(Arel.sql(expressions.join(', ')))
    end

    def tri_texte(*colonnes)
      Arel.sql(colonnes.map { |colonne| TriTextuel.expression(colonne_qualifiée(colonne)) }.join(', '))
    end

    def colonne_qualifiée(colonne)
      "#{quoted_table_name}.#{connection.quote_column_name(colonne)}"
    end
  end
end
