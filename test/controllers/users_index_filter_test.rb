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

  test 'admin : tous les services sélectionnés → tous les utilisateurs de l\'organisation' do
    tous = organisations(:mairie_paris).services.ids

    get users_url, params: { services: tous, search: @temoin.nom }

    assert_response :success
    assert_select 'a[href=?]', user_path(@temoin), { minimum: 1 },
                  'tous les services cochés → l\'admin voit toute son organisation'
  end

  # Un administrateur peut créer un compte dans n'importe quel service de son
  # organisation : ce compte doit être atteignable depuis l'index.
  test 'admin : un compte créé dans un service qui n\'est pas le sien est retrouvable' do
    créé = User.create!(nom: 'Neuf', prénom: 'Venu', email: 'neuf.venu@example.test',
                        rôle: 'agent', password: 'qtDug$d843sqACz?V',
                        service_ids: [services(:comptabilite).id])

    get users_url, params: { services: [''], search: 'Neuf' }

    assert_response :success
    assert_select 'a[href=?]', user_path(créé), { minimum: 1 }
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

  # --- Filtre Mots clés ---
  # bond est dans technique, donc dans le périmètre par défaut de administrateur_paris.

  test 'le filtre user_tag ne garde que les utilisateurs porteurs du mot clé' do
    porteur = users(:bond)
    porteur.update!(tag_list: 'secteur-nord')

    get users_url, params: { user_tag: 'secteur-nord' }

    assert_response :success
    assert_equal [porteur.id], assigns(:users).map(&:id)
  end

  test 'un mot clé inconnu rend une liste vide sans erreur' do
    get users_url, params: { user_tag: 'mot-clé-qui-n-existe-pas' }

    assert_response :success
    assert_empty assigns(:users)
  end

  test 'critique : le filtre par mot clé ne franchit pas la frontière d organisation' do
    paris = users(:bond)
    marseille = users(:nettoyeur_marseille)
    paris.update!(tag_list: 'commun')
    marseille.update!(tag_list: 'commun')

    get users_url, params: { user_tag: 'commun', services: [''] }

    assert_response :success
    assert_includes assigns(:users).map(&:id), paris.id
    assert_not_includes assigns(:users).map(&:id), marseille.id
  end

  test 'critique : la liste des mots clés proposée est bornée à l organisation' do
    users(:nettoyeur_marseille).update!(tag_list: 'secret-marseille')
    users(:bond).update!(tag_list: 'secteur-nord')

    get users_url

    assert_response :success
    assert_select 'select#user_tag option', text: 'secteur-nord'
    assert_select 'select#user_tag option', { text: 'secret-marseille', count: 0 },
                  'les mots clés d\'une autre organisation ne doivent pas être proposés'
  end
end
