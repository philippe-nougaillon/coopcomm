# frozen_string_literal: true

class CreateFactureFromCommande < ApplicationService
  def initialize(commande)
    @commande = commande
  end

  # Retourne une nouvelle commande à partir des éléments de la commande
  def call
    # Création de la commande à partir de la commande
    facture = Facture.new
    facture.adherent_id = @commande.adherent_id
    facture.service_id = @commande.service_id
    facture.intitulé = @commande.intitulé
    facture.mémo = @commande.mémo
    facture.date_livraison_souhaitée = @commande.date_livraison_souhaitée

    @commande.commande_lignes.each do |commande_ligne|
      facture.facture_lignes.build(prestation: commande_ligne.prestation, intitulé: commande_ligne.intitulé, qté: commande_ligne.qté, prix_ht: commande_ligne.prix_ht, total_ht: commande_ligne.total_ht)
    end

    return facture
  end
end
