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
    attendus = @cotation.cotation_lignes.map { |l| [l.prestation_id, l.intitulé, l.qté] }.sort
    obtenus  = commande.commande_lignes.map { |l| [l.prestation_id, l.intitulé, l.qté] }.sort
    assert_equal attendus, obtenus
  end

  test 'la commande construite persiste et recalcule son total' do
    commande = CreateCommandeFromCotation.new(@cotation).call

    assert commande.save, commande.errors.full_messages.to_sentence
    # prix_ht est re-dérivé de la prestation (25.50) × qté 3 = 76.50
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

  test 'BUG documenté : le prix du devis est écrasé par le tarif ACTUEL de la prestation à la sauvegarde' do
    # La copie `prix_ht:`/`total_ht:` du service (create_commande_from_cotation.rb:19)
    # est illusoire : CommandeLigne#set_prix_from_prestation (before_validation)
    # remplace le prix par prestation.tarif, et total_ht est une colonne générée
    # PostgreSQL (prix_ht × qté). Si le tarif change entre le devis et la commande,
    # la commande ne respecte PAS le prix du devis (potentiellement signé).
    ligne_devis = @cotation.cotation_lignes.first
    assert_equal 25.5, ligne_devis.prix_ht.to_f # prix au moment du devis

    prestations(:nettoyage_bureaux).update!(tarif: 40.00) # le tarif augmente ensuite

    commande = CreateCommandeFromCotation.new(@cotation).call
    commande.save!

    ligne_commande = commande.commande_lignes.first.reload
    assert_equal 40.0, ligne_commande.prix_ht.to_f, 'le prix copié du devis (25.50) a été écrasé'
    assert_equal 120.0, commande.reload.total_ht.to_f # 40 × 3, et non 76.50
    # Le devis, lui, n'a pas bougé : l'écart devis signé / commande est silencieux.
    assert_equal 25.5, ligne_devis.reload.prix_ht.to_f
    assert_equal 76.5, @cotation.reload.total_ht.to_f
  end
end
