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

  test 'should create new user do' do
    assert_difference('User.count') do
      post admin_create_new_user_do_url, params: {
        user: {
          nom: 'Foo',
          prénom: 'Bar',
          email: 'email@example.com',
          password: '0DcPIZIq0+f5SvCf',
          rôle: 'adhérent',
          téléphone: '0123456789',
          address: 'Mairie de Paris',
          latitude: 123.123,
          longitude: 432.120398
        }
      }
    end

    assert_redirected_to users_url
  end

  test 'create_new_user_do invalide réaffiche le formulaire en 422' do
    assert_no_difference('User.count') do
      post admin_create_new_user_do_url, params: { user: { nom: 'Foo', prénom: 'Bar', email: '', rôle: 'adhérent' } }
    end

    assert_response :unprocessable_content
  end

  test 'create_new_user_do invalide en JSON renvoie les erreurs' do
    post admin_create_new_user_do_url,
         params: { user: { nom: 'Foo', prénom: 'Bar', email: '', rôle: 'adhérent' } },
         as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
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
