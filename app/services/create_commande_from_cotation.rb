# frozen_string_literal: true

class CreateCommandeFromCotation < ApplicationService
  def initialize(cotation)
    @cotation = cotation
  end

  # Retourne une nouvelle commande à partir des éléments de la cotation
  def call
    # Création de la commande à partir de la cotation
    commande = Commande.new
    commande.adherent_id = @cotation.adherent_id
    commande.service_id = @cotation.service_id
    commande.intitulé = @cotation.intitulé
    commande.mémo = @cotation.mémo
    commande.date_livraison_souhaitée = @cotation.date_livraison_souhaitée

    @cotation.cotation_lignes.each do |cotation_ligne|
      commande.commande_lignes.build(prestation: cotation_ligne.prestation, intitulé: cotation_ligne.intitulé, qté: cotation_ligne.qté, prix_ht: cotation_ligne.prix_ht, total_ht: cotation_ligne.total_ht)
    end

    return commande
  end
end
