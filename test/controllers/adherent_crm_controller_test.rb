# frozen_string_literal: true

require 'test_helper'

class AdherentCrmControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # ==================== TESTS CRITIQUES : CLOISONNEMENT =====================
  # ==========================================================================
  # La collection affichée doit rester un sous-ensemble de policy_scope quels
  # que soient les params : apply_filters lit adhérent_ids / service_ids /
  # workflow_state bruts et les injecte dans des where sans borner le périmètre.

  test "un adhérent ne voit pas les documents d'un autre adhérent" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_marseille)
  end

  test "un adhérent ne voit pas ses cotations à l'état créé" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test "un adhérent ne voit pas ses commandes à l'état créé" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_not_includes assigns(:commandes), commandes(:commande_paris)
  end

  test "un adhérent ne voit pas ses factures à l'état créé" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'factures')

    assert_not_includes assigns(:factures), factures(:facture_paris)
  end

  test "un manager ne voit aucune cotation d'une autre organisation" do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_marseille)
  end

  test "un administrateur ne voit aucune cotation d'une autre organisation" do
    sign_in users(:administrateur_paris)

    get adherent_crm_url

    assert_not_includes assigns(:cotations), cotations(:cotation_marseille)
  end

  test "le filtre adhérent_ids ne permet pas d'atteindre un document hors périmètre" do
    sign_in users(:weil)

    get adherent_crm_url(adhérent_ids: [users(:michael_jackson).id])

    assert_empty assigns(:cotations)
  end

  test "le filtre service_ids ne permet pas d'atteindre un service d'une autre organisation" do
    sign_in users(:hidalgo)

    get adherent_crm_url(service_ids: [services(:service_marseille).id])

    assert_empty assigns(:cotations)
  end

  # ==========================================================================
  # A. Autorisation
  # ==========================================================================

  test 'un agent ne peut pas accéder au CRM' do
    sign_in users(:bond)

    get adherent_crm_url

    assert_redirected_to root_url
  end

  test 'un visiteur non connecté est renvoyé vers la connexion' do
    get adherent_crm_url

    assert_redirected_to new_user_session_url
  end

  test 'un adhérent accède au CRM' do
    sign_in users(:weil)

    get adherent_crm_url

    assert_response :success
  end

  test 'un manager accède au CRM' do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_response :success
  end

  test 'un administrateur accède au CRM' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url

    assert_response :success
  end

  # ==========================================================================
  # B. Choix de l'onglet
  # ==========================================================================

  test "sans paramètre, l'onglet affiché est celui des cotations" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_equal 'cotations', assigns(:tab)
    assert_not_nil assigns(:cotations)
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

  test 'un onglet inconnu retombe sur les cotations' do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'pwned')

    assert_equal 'cotations', assigns(:tab)
    assert_response :success
  end

  test 'un onglet vide retombe sur les cotations' do
    sign_in users(:weil)

    get adherent_crm_url(tab: '')

    assert_equal 'cotations', assigns(:tab)
    assert_response :success
  end

  # ==========================================================================
  # C. Visibilité côté adhérent
  # ==========================================================================

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

  test "les services proposés à l'adhérent sont ceux de ses documents, pas ceux de son adhésion" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_includes assigns(:services), services(:secretariat)
    assert_not_includes assigns(:services), services(:informatique)
  end

  test "aucun adhérent n'est proposé au filtre pour un adhérent" do
    sign_in users(:weil)

    get adherent_crm_url

    assert_nil assigns(:adhérents)
  end

  # ==========================================================================
  # D. Visibilité côté manager / administrateur
  # ==========================================================================

  test 'un manager ne voit que les cotations de ses services' do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_includes assigns(:cotations), cotations(:cotation_paris)
    assert_not_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test "un manager voit les brouillons « créé », contrairement à l'adhérent" do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_equal Cotation::CREE, cotations(:cotation_paris).workflow_state
    assert_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test "un administrateur voit les cotations de toute son organisation" do
    sign_in users(:administrateur_paris)

    get adherent_crm_url

    assert_includes assigns(:cotations), cotations(:cotation_paris)
    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'les adhérents des services du manager sont proposés au filtre' do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_includes assigns(:adhérents), users(:weil)
  end

  test "un manager sans document voit une collection vide sans erreur" do
    sign_in users(:michael_jackson)

    get adherent_crm_url

    assert_response :success
    assert_empty assigns(:cotations)
  end

  # ==========================================================================
  # E. Filtres
  # ==========================================================================

  test 'la recherche filtre sur la référence' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: '2026-2')

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test "la recherche filtre sur un fragment d'intitulé" do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: 'nettoyage')

    assert_includes assigns(:cotations), cotations(:cotation_paris)
    assert_not_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'la recherche est insensible à la casse' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: 'NETTOYAGE')

    assert_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test 'la recherche gère les caractères accentués' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: 'secrétariat')

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'une recherche sans résultat renvoie une collection vide' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: 'zzz-introuvable-zzz')

    assert_empty assigns(:cotations)
  end

  test 'une recherche vide ne filtre rien' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: '')

    assert_includes assigns(:cotations), cotations(:cotation_paris)
    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  # ÉPINGLAGE : le terme de recherche est interpolé dans un motif ILIKE sans
  # échappement, donc « % » et « _ » y agissent comme des jokers.
  # À inverser si l'échappement est ajouté (cf. registre).
  test 'un pour-cent dans la recherche agit comme un joker' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: '%')

    assert_includes assigns(:cotations), cotations(:cotation_paris)
    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
  end

  test 'le filtre service_ids restreint aux services demandés' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(service_ids: [services(:secretariat).id])

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test 'le filtre workflow_state accepte le libellé humanisé du menu' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(workflow_state: 'Envoyé')

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test 'un workflow_state inconnu renvoie une collection vide' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(workflow_state: 'Pwned')

    assert_empty assigns(:cotations)
  end

  test 'le filtre adhérent_ids restreint aux adhérents demandés' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(adhérent_ids: [users(:weil).id])

    assert_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test 'le filtre adherent_id restreint les commandes' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(tab: 'commandes', adherent_id: users(:weil).id)

    assert_includes assigns(:commandes), commandes(:commande_paris)
  end

  test 'le filtre adherent_id restreint les factures' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(tab: 'factures', adherent_id: users(:weil).id)

    assert_includes assigns(:factures), factures(:facture_paris)
  end

  # ÉPINGLAGE : adherent_id (sans accent) n'est appliqué qu'aux commandes et
  # aux factures ; l'onglet cotations l'ignore. À inverser si l'asymétrie est
  # corrigée (cf. registre).
  test "l'onglet cotations ignore le filtre adherent_id" do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(adherent_id: users(:michael_jackson).id)

    assert_includes assigns(:cotations), cotations(:cotation_paris)
  end

  test 'les filtres se combinent en intersection' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(search: 'Devis', workflow_state: 'Envoyé')

    assert_includes assigns(:cotations), cotations(:cotation_secretariat)
    assert_not_includes assigns(:cotations), cotations(:cotation_paris)
  end

  # ==========================================================================
  # F. Pagination
  # ==========================================================================

  test 'la première page est limitée à 15 cotations' do
    creer_cotations(20)
    sign_in users(:administrateur_paris)

    get adherent_crm_url

    assert_equal 15, assigns(:cotations).size
  end

  test 'la seconde page contient le reste des cotations' do
    creer_cotations(20)
    sign_in users(:administrateur_paris)

    get adherent_crm_url(page: 2)

    assert_equal 22, assigns(:pagy).count
    assert_equal 7, assigns(:cotations).size
  end

  test 'une page hors bornes redirige au lieu de lever une erreur' do
    sign_in users(:administrateur_paris)

    get adherent_crm_url(page: 999)

    assert_response :redirect
  end

  # ==========================================================================
  # G. Dernier mail par cotation
  # ==========================================================================

  test 'le dernier mail de chaque cotation est indexé par cotation' do
    cotation = cotations(:cotation_secretariat)
    creer_mail_log(cotation, 'ancien@example.com', 2.days.ago)
    recent = creer_mail_log(cotation, 'recent@example.com', 1.hour.ago)

    sign_in users(:weil)
    get adherent_crm_url

    assert_equal recent.id, assigns(:last_mail_logs)[cotation.id].id
  end

  test "une cotation sans mail n'a pas d'entrée dans les derniers mails" do
    sign_in users(:hidalgo)

    get adherent_crm_url

    assert_nil assigns(:last_mail_logs)[cotations(:cotation_paris).id]
  end

  test "les derniers mails ne sont pas calculés hors de l'onglet cotations" do
    sign_in users(:weil)

    get adherent_crm_url(tab: 'commandes')

    assert_nil assigns(:last_mail_logs)
  end

  # ==========================================================================
  # H. Suppression douce
  # ==========================================================================

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
