# frozen_string_literal: true

# Un formulaire soumet une chaîne vide là où la base porte NULL : sans cette
# normalisation, ouvrir puis enregistrer une fiche sans rien changer écrit
# `nil → ""` et produit un audit qui n'affiche rien.
module ChaineVideEnNil
  extend ActiveSupport::Concern

  included do
    before_validation :vide_en_nil
  end

  private

  def vide_en_nil
    self.class.columns.each do |colonne|
      next unless %i[string text].include?(colonne.type) && colonne.null

      valeur = self[colonne.name]
      self[colonne.name] = nil if valeur.is_a?(String) && valeur.strip.empty?
    end
  end
end
