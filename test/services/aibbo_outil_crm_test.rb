# frozen_string_literal: true

require 'test_helper'

class AibboOutilCrmTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Un devis, une commande ou une facture porte de l'argent : AÏBBO n'en rend que ce que l'utilisateur ouvre déjà,
  # brouillons exclus pour un adhérent, et ses montants suivent les règles du tableau de bord.
  test 'un manager ne reçoit que les documents de ses services (critique)' do
    resultat = Aibbo::OutilCrm.new(users(:manager_marseille)).call

    assert_equal [cotations(:cotation_marseille), commandes(:commande_marseille), factures(:facture_marseille)].map(&:intitulé).sort,
                 resultat[:documents].pluck(:intitulé).sort
  end

  test 'un adhérent ne reçoit que ses documents, sans les brouillons (critique)' do
    resultat = Aibbo::OutilCrm.new(users(:weil)).call

    assert_equal [cotations(:cotation_secretariat), commandes(:commande_secretariat), commandes(:commande_validée), commandes(:commande_envoyée),
                  factures(:facture_secretariat), factures(:facture_validée), factures(:facture_envoyée)].map(&:intitulé).sort,
                 resultat[:documents].pluck(:intitulé).sort
  end

  test 'un brouillon n’est jamais rendu à un adhérent, même demandé par son état (critique)' do
    resultat = Aibbo::OutilCrm.new(users(:weil)).call(etat: 'créé')

    assert_match(/ne voit pas les brouillons/, resultat[:erreur])
    assert_nil resultat[:documents]
  end

  test 'un agent ne reçoit aucun document (critique)' do
    resultat = Aibbo::OutilCrm.new(users(:bond)).call

    assert_empty resultat[:documents]
  end

  test 'le nom d’un adhérent hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilCrm.new(users(:manager_marseille)).call(adherent: 'weil')

    assert_match(/introuvable parmi les adhérents/, resultat[:erreur])
    assert_nil resultat[:documents]
  end

  test 'le chiffre d’affaires ne compte que les factures envoyées ou validées, le prévisionnel les devis et commandes ni brouillons ni refusés (critique)' do
    documents_de_janvier_et_fevrier_2023

    resultat = Aibbo::OutilCrm.new(@manager).call(du: '2023-01-01', au: '2023-02-28')

    assert_equal 500.0, resultat[:prévisionnel_devis_ht]
    assert_equal 400.0, resultat[:prévisionnel_commandes_ht]
    assert_equal 250.0, resultat[:chiffre_d_affaires_ht]
    assert_equal({ nombre: 3, montant_ht: 1249.0 }, resultat[:par_type]['facture'])
  end

  test 'une facture supprimée n’est ni rendue ni comptée (critique)' do
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture supprimée',
                    workflow_state: Facture::VALIDE, total_ht: 700, created_at: Time.zone.local(2023, 1, 10, 9)).discard!

    resultat = Aibbo::OutilCrm.new(@manager).call(du: '2023-01-01', au: '2023-01-31')

    assert_empty resultat[:documents]
    assert_equal 0.0, resultat[:chiffre_d_affaires_ht]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le filtre par type ne rend que ce type' do
    resultat = Aibbo::OutilCrm.new(@manager).call(type: 'facture')

    assert_equal ['facture'], resultat[:par_type].keys
    assert_equal ['facture'], resultat[:documents].pluck(:type).uniq
    assert_nil resultat[:prévisionnel_devis_ht]
  end

  test 'un document envoyé porte le jour de son envoi et le nombre de jours écoulés depuis' do
    devis_envoye_le(Time.zone.local(2023, 3, 1, 10))
    travel_to Time.zone.local(2023, 3, 20, 12)

    devis = Aibbo::OutilCrm.new(@manager).call(type: 'devis', du: '2023-01-01', au: '2023-12-31')[:documents].first

    assert_equal '2023-03-01', devis[:envoyé_le]
    assert_equal 19, devis[:jours_depuis_l_envoi]
  end

  test 'le filtre envoyé depuis ne garde que les documents envoyés depuis au moins ce nombre de jours' do
    ancien = devis_envoye_le(Time.zone.local(2023, 3, 1, 10))
    devis_envoye_le(Time.zone.local(2023, 3, 15, 10))
    travel_to Time.zone.local(2023, 3, 20, 12)

    resultat = Aibbo::OutilCrm.new(@manager).call(type: 'devis', du: '2023-01-01', au: '2023-12-31', envoye_depuis: 15)

    assert_equal [ancien.intitulé], resultat[:documents].pluck(:intitulé)
  end

  test 'un adhérent qui n’a aucun document est reconnu par son nom, avec zéro document' do
    resultat = Aibbo::OutilCrm.new(@manager).call(adherent: 'berthout')

    assert_nil resultat[:erreur]
    assert_empty resultat[:documents]
  end

  test 'le regroupement par adhérent additionne le nombre et le montant de chacun, le plus élevé d’abord' do
    documents_de_janvier_et_fevrier_2023
    Facture.create!(adherent: users(:berthout), service: services(:technique), intitulé: 'Facture de Berthout',
                    workflow_state: Facture::VALIDE, total_ht: 3000, created_at: Time.zone.local(2023, 2, 1, 9))

    resultat = Aibbo::OutilCrm.new(@manager).call(du: '2023-01-01', au: '2023-02-28', regrouper_par: 'adherent')

    assert_equal [{ 'adherent' => 'Weil Ariel', nombre: 6, montant_ht: 3148.0 }, { 'adherent' => 'Berthout Florence', nombre: 1, montant_ht: 3000.0 }],
                 resultat[:groupes]
  end

  private

  # Les documents du bloc « montants du CRM » du tableau de bord : un brouillon et une facture refusée à exclure des montants.
  def documents_de_janvier_et_fevrier_2023
    Cotation.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Devis envoyé',
                     workflow_state: Cotation::ENVOYE, total_ht: 500, created_at: Time.zone.local(2023, 1, 10, 9))
    Cotation.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Devis brouillon',
                     workflow_state: Cotation::CREE, total_ht: 999, created_at: Time.zone.local(2023, 1, 12, 9))
    Commande.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Commande validée',
                     workflow_state: Commande::VALIDE, total_ht: 400, created_at: Time.zone.local(2023, 2, 5, 9))
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture envoyée',
                    workflow_state: Facture::ENVOYE, total_ht: 200, created_at: Time.zone.local(2023, 2, 20, 9))
    Facture.create!(adherent: users(:weil), service: services(:technique), intitulé: 'Facture refusée',
                    workflow_state: Facture::REFUSE, total_ht: 999, created_at: Time.zone.local(2023, 2, 21, 9))
    Facture.create!(adherent: users(:weil), service: services(:informatique), intitulé: 'Facture informatique',
                    workflow_state: Facture::VALIDE, total_ht: 50, created_at: Time.zone.local(2023, 2, 22, 9))
  end

  # Un devis saisi en brouillon, puis envoyé à l'instant donné : son historique garde le jour de l'envoi.
  def devis_envoye_le(instant)
    travel_to(instant) do
      Cotation.create!(adherent: users(:weil), service: services(:technique), intitulé: "Devis envoyé le #{instant.to_date}",
                       workflow_state: Cotation::CREE, total_ht: 100).tap(&:envoyer!)
    end
  end
end
