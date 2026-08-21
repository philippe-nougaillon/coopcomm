# frozen_string_literal: true

require 'test_helper'

# Gabarit aligné sur create_facture_from_commande_test.rb (service jumeau).
class CreateCommandeFromCotationTest < ActiveSupport::TestCase
  setup do
    @cotation = cotations(:cotation_paris) # informatique, 1 ligne (nettoyage_bureaux, qté 3, prix 25.50)
  end

  test 'retourne une Commande non sauvegardée' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_instance_of Commande, commande
    assert commande.new_record?
  end

  test 'recopie les attributs de la cotation' do
    @cotation.update!(mémo: 'Accès par la cour', date_livraison_souhaitée: Date.new(2026, 9, 1))

    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_equal @cotation.adherent_id, commande.adherent_id
    assert_equal @cotation.service_id, commande.service_id
    assert_equal @cotation.intitulé, commande.intitulé
    assert_equal @cotation.mémo, commande.mémo
    assert_equal @cotation.date_livraison_souhaitée, commande.date_livraison_souhaitée
  end

  test 'construit une ligne de commande par ligne de cotation' do
    CotationLigne.create!(cotation: @cotation, prestation: prestations(:entretien_espaces_verts),
                          intitulé: 'Tonte des abords', qté: 2)

    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_equal @cotation.cotation_lignes.count, commande.commande_lignes.size
    # L'association cotation_lignes n'a pas d'ordre garanti et le service la parcourt
    # telle quelle : on compare donc les deux collections sans dépendre de la position.
    attendus = @cotation.cotation_lignes.map { |l| [l.prestation_id, l.intitulé, l.qté, l.prix_ht] }.sort
    obtenus  = commande.commande_lignes.map { |l| [l.prestation_id, l.intitulé, l.qté, l.prix_ht] }.sort
    assert_equal attendus, obtenus
  end

  test 'la commande construite persiste et recalcule son total' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert commande.save, commande.errors.full_messages.to_sentence
    # prix_ht est copié du devis (25.50) × qté 3 = 76.50
    assert_equal 76.5, commande.reload.total_ht.to_f
    assert_equal 1, commande.commande_lignes.count
  end

  test "la commande construite reçoit une ref et l'état initial à la sauvegarde" do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_nil commande.ref
    commande.save!
    assert_match(/\ACM-#{Date.current.year}-\d+\z/, commande.ref)
    assert commande.créé?
  end

  test 'expose une interface de service via ApplicationService.call' do
    commande = CreateCommandeFromCotation.call(@cotation)

    assert_instance_of Commande, commande
  end

  test 'une cotation sans ligne donne une commande valide sans ligne' do
    cotation_vide = cotations(:cotation_marseille) # aucune cotation_ligne en fixture

    commande = CreateCommandeFromCotation.new(cotation_vide).call

    assert_empty commande.commande_lignes
    assert commande.save, commande.errors.full_messages.to_sentence
    assert_equal 0, commande.reload.total_ht.to_f
  end

  test "une cotation sans intitulé donne une commande invalide (l'intitulé est obligatoire)" do
    @cotation.update_column(:intitulé, nil) # bypass : la cotation elle-même valide la présence

    commande = CreateCommandeFromCotation.new(@cotation).call

    assert_not commande.save
    assert commande.errors[:intitulé].any?
  end

  # Test critique — le prix signé sur le devis est le prix contractuel : une hausse
  # ultérieure du tarif ne doit jamais faire dériver la commande (ex-bug B2).
  test 'le prix du devis est figé : une hausse ultérieure du tarif ne change pas la commande' do
    ligne_devis = @cotation.cotation_lignes.first
    assert_equal 25.5, ligne_devis.prix_ht.to_f # prix au moment du devis

    prestations(:nettoyage_bureaux).update!(tarif: 40.00) # le tarif augmente ensuite

    commande = CreateCommandeFromCotation.new(@cotation).call
    commande.save!

    ligne_commande = commande.commande_lignes.first.reload
    assert_equal 25.5, ligne_commande.prix_ht.to_f, 'le prix du devis signé doit être conservé'
    assert_equal 76.5, commande.reload.total_ht.to_f # 25.50 × 3, et non 120.00
    assert_equal 25.5, ligne_devis.reload.prix_ht.to_f
    assert_equal 76.5, @cotation.reload.total_ht.to_f
  end
end
