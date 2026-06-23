# frozen_string_literal: true

require 'test_helper'

# Filtre Services de l'index utilisateurs (#311) : services du current_user
# présélectionnés au premier affichage, mais vidables — un administrateur qui
# retire ses services voit alors TOUS les utilisateurs de son organisation.
# Même mécanisme que l'index interventions (champ caché `services[]`).
class UsersIndexFilterTest < ActionDispatch::IntegrationTest
  setup do
    # administrateur_paris (org mairie_paris) services : service_paris /
    # informatique / technique. john_wick est dans `comptabilite` (même org,
    # hors de ses services) → témoin « hors périmètre personnel ».
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
    # L'index /users pagine (10/page) : on cible la recherche sur le témoin pour
    # un résultat déterministe, indépendant de la page. john_wick (comptabilite)
    # n'apparaît QUE si le périmètre est élargi à toute l'organisation (filtre vidé).
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
end
