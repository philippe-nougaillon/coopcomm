# frozen_string_literal: true

require 'test_helper'

class CreateFactureFromCommandeTest < ActiveSupport::TestCase
  setup do
    @commande = commandes(:commande_paris)
  end

  test 'la facture construite n’est pas encore sauvegardée' do
    facture = CreateFactureFromCommande.new(@commande).call

    assert_instance_of Facture, facture
    assert facture.new_record?
  end

  test 'la facture construite recopie les attributs de la commande' do
    @commande.update!(mémo: 'Accès par la cour', date_livraison_souhaitée: Date.new(2026, 9, 1))

    facture = CreateFactureFromCommande.new(@commande).call

    assert_equal @commande.adherent_id, facture.adherent_id
    assert_equal @commande.service_id, facture.service_id
    assert_equal @commande.intitulé, facture.intitulé
    assert_equal @commande.mémo, facture.mémo
    assert_equal @commande.date_livraison_souhaitée, facture.date_livraison_souhaitée
  end

  test 'la facture construite recopie chaque ligne de la commande' do
    facture = CreateFactureFromCommande.new(@commande).call

    assert_equal @commande.commande_lignes.size, facture.facture_lignes.size

    ligne_source = @commande.commande_lignes.first
    ligne_copie = facture.facture_lignes.first

    assert_equal ligne_source.prestation_id, ligne_copie.prestation_id
    assert_equal ligne_source.intitulé, ligne_copie.intitulé
    assert_equal ligne_source.qté, ligne_copie.qté
    assert_equal ligne_source.prix_ht, ligne_copie.prix_ht
  end

  test 'la facture construite persiste et recalcule le total de la commande' do
    facture = CreateFactureFromCommande.new(@commande).call

    assert facture.save, facture.errors.full_messages.to_sentence
    assert_equal @commande.total_ht.to_f, facture.reload.total_ht.to_f
    assert_equal @commande.commande_lignes.count, facture.facture_lignes.count
  end

  test 'la facture construite reçoit une référence et l’état initial à la sauvegarde' do
    facture = CreateFactureFromCommande.new(@commande).call

    assert_nil facture.ref
    facture.save!

    assert_match(/\AFA-#{Date.current.year}-\d+\z/, facture.ref)
    assert_predicate facture, :créé?
  end

  test 'une facture se construit aussi par un appel de classe' do
    facture = CreateFactureFromCommande.call(@commande)

    assert_instance_of Facture, facture
  end

  test 'une commande sans ligne donne une facture valide sans ligne' do
    commande_sans_ligne = commandes(:commande_marseille)

    facture = CreateFactureFromCommande.new(commande_sans_ligne).call

    assert_empty commande_sans_ligne.commande_lignes, 'garde : fixture sans ligne'
    assert_empty facture.facture_lignes
    assert facture.save, facture.errors.full_messages.to_sentence
    assert_equal commande_sans_ligne.total_ht.to_f, facture.reload.total_ht.to_f
  end

  test 'une commande sans intitulé donne une facture invalide' do
    @commande.update_column(:intitulé, nil)

    facture = CreateFactureFromCommande.new(@commande).call

    assert_not facture.save
    assert_predicate facture.errors[:intitulé], :any?
  end

  test 'le prix de la commande est figé : une hausse ultérieure du tarif ne change pas la facture (critique)' do
    ligne_commande = @commande.commande_lignes.first
    prix_de_la_commande = ligne_commande.prix_ht
    total_de_la_commande = @commande.total_ht.to_f
    tarif_augmenté = prix_de_la_commande + 15

    prestations(:nettoyage_bureaux).update!(tarif: tarif_augmenté)

    facture = CreateFactureFromCommande.new(@commande).call
    facture.save!
    ligne_facture = facture.facture_lignes.first.reload

    assert_equal prix_de_la_commande, ligne_facture.prix_ht
    assert_not_equal tarif_augmenté, ligne_facture.prix_ht, 'le tarif courant de la prestation ne doit pas changer le prix de la ligne de la facture'
    assert_equal total_de_la_commande, facture.reload.total_ht.to_f
    assert_equal prix_de_la_commande, ligne_commande.reload.prix_ht
  end
end
