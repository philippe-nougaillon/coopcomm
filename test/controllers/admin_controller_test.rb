# frozen_string_literal: true

require 'test_helper'

# `stats` est réservé au super administrateur, donc hors périmètre.
class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @audit = Audited::Audit.create!(auditable: users(:bond), user: users(:hidalgo), action: 'update',
                                    audited_changes: { 'nom' => %w[AVANT SONDEAUDIT] })
    sign_in users(:administrateur_paris)
  end

  test 'la liste des audits est affichée avec succès' do
    get admin_audits_url

    assert_response :success
  end

  test 'la recherche dans la liste ne retourne que les audits dont les changements correspondent' do
    get admin_audits_url(search: 'SONDEAUDIT')

    assert_includes assigns(:audits), @audit
    assert_equal 1, assigns(:audits).size
  end

  test 'la liste filtrée par date de début ne retourne que les audits postérieurs' do
    get admin_audits_url(start_date: (Date.current + 1).to_s)

    assert_not_includes assigns(:audits), @audit
  end

  test 'la liste filtrée par date de fin ne retourne que les audits antérieurs' do
    get admin_audits_url(end_date: (Date.current - 1).to_s)

    assert_not_includes assigns(:audits), @audit
  end

  test 'la liste filtrée par utilisateur ne retourne que les audits de cet utilisateur' do
    get admin_audits_url(user_id: [users(:hidalgo).id])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(user_id: [users(:bond).id])
    assert_not_includes assigns(:audits), @audit
  end

  test 'la liste filtrée par type ne retourne que les audits de ce type d’enregistrement' do
    get admin_audits_url(type: ['User'])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(type: ['Intervention'])
    assert_not_includes assigns(:audits), @audit
  end

  test 'la liste filtrée par action ne retourne que les audits de cette action' do
    get admin_audits_url(action_name: ['update'])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(action_name: ['destroy'])
    assert_not_includes assigns(:audits), @audit
  end

  test 'la page des paramètres est affichée avec succès' do
    get admin_parametres_url

    assert_response :success
  end

  test 'la recherche dans les paramètres ne retourne que les services correspondants' do
    get admin_parametres_url(search: 'Technique')

    assert_includes assigns(:services), services(:technique)
    assert_not_includes assigns(:services), services(:comptabilite)
  end

  test 'les paramètres filtrés par utilisateur ne retournent que les services de cet utilisateur, sans prestation' do
    get admin_parametres_url(user_id: [users(:weil).id])

    assert_includes assigns(:services), services(:informatique)
    assert_equal 0, assigns(:prestations_count)
  end

  test 'l’onglet sites des paramètres ne pagine que les sites' do
    get admin_parametres_url(tab: 'sites')

    assert_includes assigns(:warehouses), warehouses(:entrepot_paris)
    assert_empty assigns(:services)
    assert_empty assigns(:prestations)
  end

  test 'l’onglet prestations des paramètres ne pagine que les prestations' do
    get admin_parametres_url(tab: 'prestations')

    assert_includes assigns(:prestations), prestations(:nettoyage_bureaux)
    assert_empty assigns(:services)
    assert_empty assigns(:warehouses)
  end
end
