# frozen_string_literal: true

require 'test_helper'

# `stats` est réservé au super administrateur, donc hors périmètre.
class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @audit = Audited::Audit.create!(auditable: users(:bond), user: users(:hidalgo), action: 'update',
                                    audited_changes: { 'nom' => %w[AVANT SONDEAUDIT] })
    sign_in users(:administrateur_paris)
  end

  test 'audits : sans paramètre → la page répond' do
    get admin_audits_url

    assert_response :success
  end

  test 'audits : recherche → seulement les audits dont les changements correspondent' do
    get admin_audits_url(search: 'SONDEAUDIT')

    assert_includes assigns(:audits), @audit
    assert_equal 1, assigns(:audits).size
  end

  test 'audits : start_date → seulement les audits postérieurs' do
    get admin_audits_url(start_date: (Date.current + 1).to_s)

    assert_not_includes assigns(:audits), @audit
  end

  test 'audits : end_date → seulement les audits antérieurs' do
    get admin_audits_url(end_date: (Date.current - 1).to_s)

    assert_not_includes assigns(:audits), @audit
  end

  test 'audits : user_id → seulement les audits de cet utilisateur' do
    get admin_audits_url(user_id: [users(:hidalgo).id])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(user_id: [users(:bond).id])
    assert_not_includes assigns(:audits), @audit
  end

  test 'audits : type → seulement les audits de ce type d’enregistrement' do
    get admin_audits_url(type: ['User'])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(type: ['Intervention'])
    assert_not_includes assigns(:audits), @audit
  end

  test 'audits : action_name → seulement les audits de cette action' do
    get admin_audits_url(action_name: ['update'])
    assert_includes assigns(:audits), @audit

    get admin_audits_url(action_name: ['destroy'])
    assert_not_includes assigns(:audits), @audit
  end

  test 'create_new_user : sans paramètre → la page répond' do
    get admin_create_new_user_url

    assert_response :success
  end

  test 'create_new_user : le formulaire s’ouvre sur le rôle agent' do
    get admin_create_new_user_url

    assert_equal 'agent', assigns(:user).rôle
  end

  # `POST /users` appartient à Devise dès que :registerable est réactivé : le
  # formulaire doit viser le chemin dédié, sans quoi la création est captée par
  # l'inscription publique et aucun compte n'est créé.
  test 'create_new_user : le formulaire poste sur le chemin dédié, pas sur POST /users' do
    get admin_create_new_user_url

    assert_select 'form[action=?][method=?]', admin_create_new_user_do_path, 'post'
  end

  test 'parametres : sans paramètre → la page répond' do
    get admin_parametres_url

    assert_response :success
  end

  test 'parametres : recherche → les trois catalogues sont filtrés' do
    get admin_parametres_url(search: 'Technique')

    assert_includes assigns(:services), services(:technique)
    assert_not_includes assigns(:services), services(:comptabilite)
  end

  test 'parametres : user_id → les services de cet utilisateur, sans prestation' do
    get admin_parametres_url(user_id: [users(:weil).id])

    assert_includes assigns(:services), services(:informatique)
    assert_equal 0, assigns(:prestations_count)
  end

  test 'parametres : onglet sites → seuls les sites sont paginés' do
    get admin_parametres_url(tab: 'sites')

    assert_includes assigns(:warehouses), warehouses(:entrepot_paris)
    assert_empty assigns(:services)
    assert_empty assigns(:prestations)
  end

  test 'parametres : onglet prestations → seules les prestations sont paginées' do
    get admin_parametres_url(tab: 'prestations')

    assert_includes assigns(:prestations), prestations(:nettoyage_bureaux)
    assert_empty assigns(:services)
    assert_empty assigns(:warehouses)
  end
end
