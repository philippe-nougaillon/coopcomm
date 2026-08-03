# frozen_string_literal: true

require 'test_helper'

class AdminControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bond)
    sign_in users(:hidalgo)
  end

  test 'should get audits' do
    get admin_audits_url
    assert_response :success
  end

  test 'should get parametres (rend le catalogue de prestations)' do
    sign_in users(:administrateur_paris)
    get admin_parametres_url
    assert_response :success
  end

  test 'should get create new user' do
    get admin_create_new_user_url
    assert_response :success
  end

  # `POST /users` appartient à Devise dès que :registerable est réactivé : le
  # formulaire doit viser le chemin dédié, sans quoi la création est captée par
  # l'inscription publique et aucun compte n'est créé.
  test 'le formulaire de création poste sur le chemin dédié, pas sur POST /users' do
    get admin_create_new_user_url

    assert_response :success
    assert_select "form[action=?][method=?]", admin_create_new_user_do_path, 'post'
  end

  test 'create_new_user prépare un agent par défaut' do
    sign_in users(:administrateur_paris)

    get admin_create_new_user_url

    assert_equal 'agent', assigns(:user).rôle
  end

  # --- stats : réservé au super administrateur ---

  test 'stats est accessible au super administrateur et liste les organisations' do
    super_admin = users(:philippe_super_admin)
    super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = super_admin.email
    sign_in super_admin

    get admin_stats_url

    assert_response :success
    assert_includes assigns(:organisations), organisations(:mairie_paris)
  ensure
    ENV['SUPER_ADMIN'] = super_admin_initial
    ENV.delete('SUPER_ADMIN') if super_admin_initial.nil?
  end

  # --- parametres : filtres et onglets ---

  test 'parametres filtre les trois catalogues sur le texte recherché' do
    sign_in users(:administrateur_paris)

    get admin_parametres_url(search: 'Technique')

    assert_response :success
    assert_includes assigns(:services), services(:technique)
    assert_not_includes assigns(:services), services(:comptabilite)
  end

  test 'parametres filtre par utilisateur et vide alors le catalogue de prestations' do
    sign_in users(:administrateur_paris)

    get admin_parametres_url(user_id: [users(:weil).id])

    assert_response :success
    assert_includes assigns(:services), services(:informatique)
    assert_equal 0, assigns(:prestations_count)
  end

  test 'parametres sur l\'onglet sites ne pagine que les sites' do
    sign_in users(:administrateur_paris)

    get admin_parametres_url(tab: 'sites')

    assert_response :success
    assert_includes assigns(:warehouses), warehouses(:entrepot_paris)
    assert_empty assigns(:services)
    assert_empty assigns(:prestations)
  end

  test 'parametres sur l\'onglet prestations ne pagine que les prestations' do
    sign_in users(:administrateur_paris)

    get admin_parametres_url(tab: 'prestations')

    assert_response :success
    assert_includes assigns(:prestations), prestations(:nettoyage_bureaux)
    assert_empty assigns(:services)
    assert_empty assigns(:warehouses)
  end
end
