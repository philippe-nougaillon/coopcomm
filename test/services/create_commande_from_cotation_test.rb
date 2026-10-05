# frozen_string_literal: true

require 'test_helper'

class CreateCommandeFromCotationTest < ActiveSupport::TestCase
  setup do
    @cotation = cotations(:cotation_paris)
  end

  test 'la commande construite n’est pas encore sauvegardée' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_instance_of Commande, commande
    assert commande.new_record?
  end

  test 'la commande construite recopie les attributs de la cotation' do
    @cotation.update!(mémo: 'Accès par la cour', date_livraison_souhaitée: Date.new(2026, 9, 1))

    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_equal @cotation.adherent_id, commande.adherent_id
    assert_equal @cotation.service_id, commande.service_id
    assert_equal @cotation.intitulé, commande.intitulé
    assert_equal @cotation.mémo, commande.mémo
    assert_equal @cotation.date_livraison_souhaitée, commande.date_livraison_souhaitée
  end

  test 'la commande construite recopie chaque ligne de la cotation' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_equal @cotation.cotation_lignes.size, commande.commande_lignes.size

    ligne_source = @cotation.cotation_lignes.first
    ligne_copie = commande.commande_lignes.first

    assert_equal ligne_source.prestation_id, ligne_copie.prestation_id
    assert_equal ligne_source.intitulé, ligne_copie.intitulé
    assert_equal ligne_source.qté, ligne_copie.qté
    assert_equal ligne_source.prix_ht, ligne_copie.prix_ht
  end

  test 'la commande construite persiste et recalcule le total de la cotation' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert commande.save, commande.errors.full_messages.to_sentence
    assert_equal @cotation.total_ht.to_f, commande.reload.total_ht.to_f
    assert_equal @cotation.cotation_lignes.count, commande.commande_lignes.count
  end

  test 'la commande construite reçoit une référence et l’état initial à la sauvegarde' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_nil commande.ref
    commande.save!

    assert_match(/\ACM-#{Date.current.year}-\d+\z/, commande.ref)
    assert_predicate commande, :créé?
  end

  test 'une commande se construit aussi par un appel de classe' do
    commande = CreateCommandeFromCotation.call(@cotation)

    assert_instance_of Commande, commande
  end

  test 'une cotation sans ligne donne une commande valide sans ligne' do
    cotation_sans_ligne = cotations(:cotation_marseille)

    commande = CreateCommandeFromCotation.new(cotation_sans_ligne).call

    assert_empty cotation_sans_ligne.cotation_lignes, 'garde : fixture sans ligne'
    assert_empty commande.commande_lignes
    assert commande.save, commande.errors.full_messages.to_sentence
    assert_equal cotation_sans_ligne.total_ht.to_f, commande.reload.total_ht.to_f
  end

  test 'une cotation sans intitulé donne une commande invalide' do
    @cotation.update_column(:intitulé, nil)

    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_not commande.save
    assert_predicate commande.errors[:intitulé], :any?
  end

  test 'le prix du devis est figé : une hausse ultérieure du tarif ne change pas la commande (critique)' do
    ligne_devis = @cotation.cotation_lignes.first
    prix_du_devis = ligne_devis.prix_ht
    total_du_devis = @cotation.total_ht.to_f
    tarif_augmenté = prix_du_devis + 15

    prestations(:nettoyage_bureaux).update!(tarif: tarif_augmenté)

    commande = CreateCommandeFromCotation.new(@cotation).call
    commande.save!
    ligne_commande = commande.commande_lignes.first.reload

    assert_equal prix_du_devis, ligne_commande.prix_ht
    assert_not_equal tarif_augmenté, ligne_commande.prix_ht, 'le tarif courant de la prestation ne doit pas changer le prix de la ligne de la commande'
    assert_equal total_du_devis, commande.reload.total_ht.to_f
    assert_equal prix_du_devis, ligne_devis.reload.prix_ht
  end
end
