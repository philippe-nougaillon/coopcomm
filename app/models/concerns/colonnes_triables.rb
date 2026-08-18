# frozen_string_literal: true

# Catalogue des colonnes par lesquelles un modèle peut être trié, déclaré DANS LE
# MODÈLE : les expressions qui reflètent une méthode Ruby (`User#moyenne`) vivent
# ainsi à côté d'elle. Ce fichier ne trie rien et ne connaît ni requête ni vue —
# il est lu par `Triable.trie` côté contrôleur, qui applique l'ordre.
#
#   triable_par({ 'users.nom' => :texte, 'users.moyenne' => '(SELECT AVG(…))' },
#               puis: TriTextuel.expression('users.prénom'))
#
# `:texte` ignore accents et majuscules, `:brut` trie la colonne telle quelle,
# une chaîne est une expression SQL libre — sous-requête scalaire de préférence,
# pour ne jamais dupliquer de ligne.
module ColonnesTriables
  extend ActiveSupport::Concern

  included do
    class_attribute :colonnes_triables, default: {}, instance_writer: false
    class_attribute :tri_secondaire, default: nil, instance_writer: false
  end

  class_methods do
    # Les colonnes s'écrivent avec ou sans accolades ; sans, Ruby les livre en
    # arguments nommés, d'où la double lecture.
    def triable_par(colonnes = nil, **options)
      self.colonnes_triables = colonnes_triables.merge((colonnes || options.except(:puis)).transform_keys(&:to_s))
      self.tri_secondaire = options[:puis] if options[:puis]
    end
  end
end
