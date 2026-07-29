# frozen_string_literal: true

require 'test_helper'

# Filtre Services de l'index utilisateurs (#311) : services du current_user
# présélectionnés au premier affichage, mais vidables.
class UsersIndexFilterTest < ActionDispatch::IntegrationTest
  setup do
    # administrateur_paris (org mairie_paris) services : service_paris / informatique /
    # technique.
    sign_in users(:administrateur_paris)
    @temoin = users(:john_wick)
  end

  test 'admin : premier affichage → pré-filtré sur ses services (témoin masqué)' do
    get users_url # aucun paramètre soumis

    assert_response :success
    assert_select 'a[href=?]', user_path(@temoin), { count: 0 },
                  'par défaut, un utilisateur hors des services de l\'admin ne doit pas apparaître'
  end

  test 'admin : filtre vidé (services[] soumis vide) → tous les utilisateurs de l\'organisation' do
    # L'index /users pagine (10/page) : on cible la recherche sur le témoin pour un
    # résultat déterministe, indépendant de la page.
    get users_url, params: { services: [''], search: @temoin.nom }

    assert_response :success
    assert_select 'a[href=?]', user_path(@temoin), { minimum: 1 },
                  'filtre vidé → l\'admin voit toute son organisation (témoin hors de ses services trouvé)'
    assert_select "select[name='services[]'] option[selected]", false,
                  'filtre vidé → aucun service présélectionné'
  end

  test 'admin : sans vider le filtre, un utilisateur hors de ses services reste masqué' do
    # services non soumis → défaut = ses services présélectionnés. Même avec une
    # recherche ciblée, john_wick (comptabilite) reste hors périmètre.
    get users_url, params: { search: @temoin.nom }

    assert_response :success
    assert_select 'a[href=?]', user_path(@temoin), { count: 0 },
                  'par défaut (services présélectionnés), un utilisateur hors de ses services ne doit pas apparaître'
  end

  test 'admin : choix explicite d\'un service → seulement ses utilisateurs' do
    get users_url, params: { services: [services(:comptabilite).id] }

    assert_response :success
    assert_select 'a[href=?]', user_path(@temoin), { minimum: 1 } # john_wick est dans comptabilite
  end

  test 'le formulaire /users fournit le champ caché services[] (permet de vider le filtre)' do
    get users_url

    assert_response :success
    assert_select "input[type=hidden][name='services[]']", { minimum: 1 },
                  'un champ caché services[] doit toujours être soumis pour distinguer vide/non-soumis'
  end

  # --- Manager : filtre vide par défaut (pas de présélection) -----------------

  test 'manager : premier affichage → aucun service présélectionné (filtre vide)' do
    sign_in users(:hidalgo) # manager, 3 services

    get users_url

    assert_response :success
    assert_select "select[name='services[]'] option[selected]", false,
                  'un manager ne doit avoir aucun service présélectionné par défaut'
  end

  test 'manager mono-service : le filtre services est masqué' do
    sign_in users(:manager_marseille) # un seul service

    get users_url

    assert_response :success
    assert_select "select[name='services[]']", false,
                  'le filtre services doit être masqué pour un manager mono-service'
  end
end
