# frozen_string_literal: true

require 'test_helper'

class AdherentCrmControllerTest < ActionDispatch::IntegrationTest
  # La collection affichée doit rester un sous-ensemble de policy_scope quels
  # que soient les params : apply_filters lit adhérent_ids / service_ids /
  # workflow_state bruts et les injecte dans des where sans borner le périmètre.

  # ==================== TESTS CRITIQUES ====================

  test "un adhérent ne voit pas la cotation d'un autre adhérent de son organisation (critique)" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_envoyée)
  end

  test "un adhérent ne voit aucune cotation d'une autre organisation (critique)" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_marseille)
  end

  test "un adhérent ne voit pas ses cotations à l'état créé (critique)" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test "un adhérent ne voit pas ses commandes à l'état créé (critique)" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_not_includes assigns(:commandes), commandes(:commande_paris)
  end

  test "un adhérent ne voit pas ses factures à l'état créé (critique)" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'factures')

    assert_not_includes assigns(:factures), factures(:facture_paris)
  end

  test "le filtre adhérent_ids ne permet pas d'atteindre un document hors périmètre (critique)" do
    sign_in users(:weil)

    get adherent_crm_url(adhérent_ids: [users(:michael_jackson).id])

    assert_empty assigns(:cotations)
  end

  test "le filtre service_ids ne permet pas d'atteindre un service d'une autre organisation (critique)" do
    sign_in users(:weil)

    get adherent_crm_url(service_ids: [services(:service_marseille).id])

    assert_empty assigns(:cotations)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la page du CRM adhérent est affichée avec succès' do
    sign_in users(:weil)

    get adherent_crm_url

    assert_response :success
  end

  test "l'onglet des cotations est affiché par défaut" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_equal 'cotations', assigns(:tab)
    assert_not_nil assigns(:cotations)
  end

  test 'un onglet inconnu affiche les cotations' do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'pwned')

    assert_equal 'cotations', assigns(:tab)
    assert_response :success
  end

  test 'un onglet vide affiche les cotations' do
    sign_in users(:weil)

    get adherent_crm_url(tab: '')

    assert_equal 'cotations', assigns(:tab)
    assert_response :success
  end

  test "l'onglet commandes ne prépare que les commandes" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_equal 'commandes', assigns(:tab)
    assert_not_nil assigns(:commandes)
    assert_nil assigns(:cotations)
    assert_nil assigns(:factures)
  end

  test "l'onglet factures ne prépare que les factures" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'factures')

    assert_equal 'factures', assigns(:tab)
    assert_not_nil assigns(:factures)
    assert_nil assigns(:cotations)
    assert_nil assigns(:commandes)
  end

  test 'un adhérent voit ses cotations envoyées' do
    sign_in users(:weil)

    get adherent_crm_url

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'un adhérent voit ses commandes envoyées et validées' do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_includes assigns(:commandes), commandes(:commande_secretariat)
    assert_includes assigns(:commandes), commandes(:commande_validée)
  end

  test 'un adhérent voit ses factures envoyées et validées' do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'factures')

    assert_includes assigns(:factures), factures(:facture_secretariat)
    assert_includes assigns(:factures), factures(:facture_validée)
  end

  test "un adhérent voit une cotation portant sur un service dont il n'est pas membre" do
    weil = users(:weil)
    cotation = cotations(:cotation_secretariat)

    assert_not_includes weil.services, cotation.service

    sign_in weil
    get adherent_crm_url

    assert_includes assigns(:cotations), cotation
  end

  test "les services proposés au filtre sont ceux des documents de l'adhérent, pas ceux de son adhésion" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_includes assigns(:services), services(:secretariat)
    assert_not_includes assigns(:services), services(:informatique)
  end

  test 'un adhérent sans document voit une liste vide sans erreur' do
    sign_in users(:berthout)

    get adherent_crm_url

    assert_response :success
    assert_empty assigns(:cotations)
  end

  test 'la recherche ne retourne que les cotations dont la référence correspond' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: '2026-4')

    assert_includes assigns(:cotations), cotations(:cotation_envoyée)
    assert_not_includes assigns(:cotations), cotations(:cotation_validée)
  end

  test "la recherche ne retourne que les cotations dont l'intitulé correspond" do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: 'informatique validé')

    assert_includes assigns(:cotations), cotations(:cotation_validée)
    assert_not_includes assigns(:cotations), cotations(:cotation_envoyée)
  end

  test 'la recherche est insensible à la casse' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: 'INFORMATIQUE VALIDÉ')

    assert_includes assigns(:cotations), cotations(:cotation_validée)
  end

  test 'la recherche gère les caractères accentués' do
    sign_in users(:weil)

    get adherent_crm_url(search: 'secrétariat')

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'une recherche sans résultat renvoie une liste vide' do
    sign_in users(:weil)

    get adherent_crm_url(search: 'zzz-introuvable-zzz')

    assert_empty assigns(:cotations)
  end

  test 'une recherche vide ne filtre aucune cotation' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: '')

    assert_includes assigns(:cotations), cotations(:cotation_envoyée)
    assert_includes assigns(:cotations), cotations(:cotation_validée)
  end

  # À inverser si l'échappement est ajouté (cf. registre).
  test 'un pour-cent dans la recherche agit comme un joker' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: '%')

    assert_includes assigns(:cotations), cotations(:cotation_envoyée)
    assert_includes assigns(:cotations), cotations(:cotation_validée)
  end

  test 'le filtre service_ids écarte les documents des autres services' do
    sign_in users(:weil)

    get adherent_crm_url(service_ids: [services(:informatique).id])

    assert_empty assigns(:cotations)
  end

  test 'le filtre workflow_state accepte le libellé humanisé du menu' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(workflow_state: 'Envoyé')

    assert_includes assigns(:cotations), cotations(:cotation_envoyée)
    assert_not_includes assigns(:cotations), cotations(:cotation_validée)
  end

  test 'un workflow_state inconnu renvoie une liste vide' do
    sign_in users(:weil)

    get adherent_crm_url(workflow_state: 'Pwned')

    assert_empty assigns(:cotations)
  end

  test 'le filtre adhérent_ids restreint aux adhérents demandés' do
    sign_in users(:weil)

    get adherent_crm_url(adhérent_ids: [users(:weil).id])

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'les filtres se combinent en intersection' do
    sign_in users(:patrick_adherent_paris)

    get adherent_crm_url(search: 'Devis', workflow_state: 'Envoyé')

    assert_includes assigns(:cotations), cotations(:cotation_envoyée)
    assert_not_includes assigns(:cotations), cotations(:cotation_validée)
  end

  test 'la première page est limitée à 10 cotations' do
    creer_cotations(20)
    sign_in users(:weil)

    get adherent_crm_url

    assert_equal 10, assigns(:cotations).size
  end

  test 'la seconde page contient le reste des cotations' do
    creer_cotations(20)
    sign_in users(:weil)
    total = Cotation.visible_to(users(:weil)).count

    get adherent_crm_url(page: 2)

    assert_equal total, assigns(:pagy).count
    assert_equal 10, assigns(:cotations).size
  end

  test 'une page hors bornes redirige au lieu de lever une erreur' do
    sign_in users(:weil)

    get adherent_crm_url(page: 999)

    assert_response :redirect
  end

  test 'le dernier mail log de chaque cotation est exposé à la vue' do
    cotation = cotations(:cotation_secretariat)
    creer_mail_log(cotation, 'ancien@example.com', 2.days.ago)
    recent = creer_mail_log(cotation, 'recent@example.com', 1.hour.ago)

    sign_in users(:weil)
    get adherent_crm_url

    assert_equal recent.id, assigns(:last_mail_logs)[cotation.id].id
  end

  test "une cotation sans mail log n'a pas d'entrée dans les derniers mails logs" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_nil assigns(:last_mail_logs)[cotations(:cotation_secretariat).id]
  end

  test "les derniers mails logs ne sont pas calculés hors de l'onglet cotations" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_nil assigns(:last_mail_logs)
  end

  test 'une cotation supprimée est invisible' do
    cotation = cotations(:cotation_secretariat)
    cotation.discard!

    sign_in users(:weil)
    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotation
  end

  test 'une commande supprimée est invisible' do
    commande = commandes(:commande_secretariat)
    commande.discard!

    sign_in users(:weil)
    get adherent_crm_url(tab: 'commandes')

    assert_not_includes assigns(:commandes), commande
  end

  test 'une facture supprimée est invisible' do
    facture = factures(:facture_secretariat)
    facture.discard!

    sign_in users(:weil)
    get adherent_crm_url(tab: 'factures')

    assert_not_includes assigns(:factures), facture
  end

  private

  def creer_cotations(nombre)
    nombre.times do |i|
      Cotation.create!(
        adherent: users(:weil),
        service: services(:informatique),
        intitulé: "Cotation de pagination #{i}",
        workflow_state: Cotation::ENVOYE,
        total_ht: 0
      )
    end
  end

  def creer_mail_log(cotation, destinataire, envoye_le)
    MailLog.create!(
      to: destinataire,
      subject: 'Cotation envoyée',
      organisation: organisations(:mairie_paris),
      cotation: cotation,
      channel: 0,
      created_at: envoye_le
    )
  end
end
