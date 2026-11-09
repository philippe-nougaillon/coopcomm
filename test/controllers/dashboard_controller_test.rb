# frozen_string_literal: true

require 'test_helper'

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test 'le tableau de bord est affiché pour un manager' do
    sign_in users(:hidalgo)

    get dashboard_url

    assert_response :success
  end

  test 'le tableau de bord est affiché pour un adhérent' do
    sign_in users(:weil)

    get dashboard_url

    assert_response :success
  end

  test 'le tableau de bord est affiché pour un manager sans intervention' do
    sign_in users(:michael_jackson)

    get dashboard_url

    assert_response :success
  end

  test 'le tableau de bord est affiché pour un adhérent sans intervention' do
    sign_in users(:emmanuel_valls)

    get dashboard_url

    assert_response :success
  end

  test 'le tableau de bord ne calcule que ses quatre tuiles' do
    sign_in users(:hidalgo)

    get dashboard_url

    assert_nil assigns(:temps_total_par_agent)
    assert_nil assigns(:donnees_graphes)[:materiel]
  end

  test 'une requête de cadre Turbo sur le tableau de bord ne rend que l’activité des agents' do
    sign_in users(:hidalgo)

    get dashboard_url, headers: { 'Turbo-Frame' => 'activite-agents' }

    assert_response :success
    assert_dom 'turbo-frame#activite-agents section[data-carte=activiteAgents]'
    assert_dom 'section[data-carte=crm]', count: 0
  end

  test 'le tableau de bord affiche le calendrier des outils en grandes cases par défaut' do
    sign_in users(:hidalgo)

    get dashboard_url

    assert_dom 'section[data-carte=reservations] [data-graphe][data-cases=hauteur]'
  end

  test 'le tableau de bord affiche le calendrier des outils en petites cases sur demande' do
    sign_in users(:hidalgo)

    get dashboard_url(outils: 'petites')

    assert_dom 'section[data-carte=reservations] [data-graphe]:not([data-cases])'
  end

  test 'les filtres du tableau de bord conservent les petites cases du calendrier des outils' do
    sign_in users(:hidalgo)

    get dashboard_url(outils: 'petites')

    assert_dom 'form input[type=hidden][name=outils][value=petites]'
  end
end
