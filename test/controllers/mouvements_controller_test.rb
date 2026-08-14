# frozen_string_literal: true

require 'test_helper'

class MouvementsControllerTest < ActionDispatch::IntegrationTest
  JOUR = Date.new(2026, 6, 2)

  setup do
    @mouvement = mouvements(:mouvement_tondeuse)
    @outil = tools(:cisaille)
    sign_in users(:administrateur_paris)
  end

  test 'index : sans paramètre → la page répond' do
    get mouvements_url

    assert_response :success
  end

  test 'new : sans paramètre → la page répond' do
    get new_mouvement_url

    assert_response :success
  end

  test 'create : paramètres valides → le mouvement est créé' do
    assert_difference('Mouvement.count') do
      post mouvements_url, params: { mouvement: { tool_id: @mouvement.tool_id, état: @mouvement.état,
                                                  date: DateTime.now } }
    end

    assert_redirected_to mouvements_path
  end

  # Arrivée via /mouvements/new sans tool_id : le select doit rester affiché pour
  # que l'utilisateur corrige son choix.
  test 'create : invalide sans tool_id imposé → le select reste affiché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url, params: { mouvement: { tool_id: @mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'select[name=?]', 'mouvement[tool_id]'
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]', false
  end

  # Arrivée via new_mouvement_path(tool_id:) : l'outil ne doit pas être modifiable
  # dans ce parcours, le champ reste donc caché.
  test 'create : invalide avec tool_id imposé → le champ reste caché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url, params: { tool_id: @mouvement.tool_id,
                                     mouvement: { tool_id: @mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]'
    assert_select 'select[name=?]', 'mouvement[tool_id]', false
  end

  test 'edit : un mouvement de son organisation → la page répond' do
    get edit_mouvement_url(@mouvement)

    assert_response :success
  end

  test 'update : paramètres valides → le mouvement est modifié' do
    patch mouvement_url(@mouvement), params: { mouvement: { tool_id: @mouvement.tool_id, état: @mouvement.état,
                                                            date: DateTime.now + 1.day } }

    assert_redirected_to mouvements_path
  end

  test 'update : date vidée → formulaire réaffiché en 422 et mouvement inchangé' do
    patch mouvement_url(@mouvement), params: { mouvement: { date: '' } }

    assert_response :unprocessable_content
    assert_not_nil @mouvement.reload.date
  end

  # Parcours quotidien des agents : une réservation perdue, ou celle d'un collègue
  # libérée par erreur, immobilise ou libère du matériel à tort.

  # ==================== TESTS CRITIQUES ====================

  test 'reserve : un outil de son organisation → une réservation à son nom (critique)' do
    assert_difference('Mouvement.count', 1) do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s }
    end

    mouvement = Mouvement.order(:id).last
    assert mouvement.réservé?
    assert_equal users(:administrateur_paris), mouvement.user
    assert_equal JOUR, mouvement.date
    assert_equal @outil, mouvement.tool
  end

  test 'reserve : un outil d’une autre organisation → introuvable, aucune réservation (critique)' do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: tools(:camion).id), params: { date: JOUR.to_s }
    end

    assert_response :not_found
  end
  # ==================== /TESTS CRITIQUES ====================

  test 'reserve : date illisible → aucune réservation et alerte' do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: 'pas-une-date' }
    end

    assert_redirected_to tools_path
    assert_equal 'Date de réservation invalide.', flash[:alert]
  end

  # ÉPINGLAGE : rien n'empêche de réserver deux fois le même outil le même jour.
  # La grille n'en affiche qu'une. À inverser si le métier tranche.
  test 'reserve : deux fois le même jour → deux réservations' do
    assert_difference('Mouvement.count', 2) do
      2.times { post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s } }
    end
  end

  # ==================== TESTS CRITIQUES ====================

  test 'libere : sa propre réservation → elle est supprimée (critique)' do
    mienne = reservation(users(:administrateur_paris))

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert_not Mouvement.exists?(mienne.id)
    assert_redirected_to tools_path
  end

  test 'libere : par un manager, la réservation d’un autre → elle est supprimée (critique)' do
    sign_in users(:hidalgo)
    celle_dun_autre = reservation(users(:bond))

    post libere_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s, user_id: users(:bond).id }

    assert_not Mouvement.exists?(celle_dun_autre.id)
  end

  test 'libere : par un agent, sa propre réservation → elle est supprimée (critique)' do
    sign_in users(:bond)
    la_mienne = reservation(users(:bond))

    post libere_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s, user_id: users(:bond).id }

    assert_not Mouvement.exists?(la_mienne.id)
  end

  # La substitution silencieuse d'un `user_id` forgé par celui du current_user
  # libérerait la réservation de l'agent au lieu de refuser la requête.
  test 'libere : requête forgée par un agent → aucune réservation détruite (critique)' do
    sign_in users(:bond)
    la_mienne = reservation(users(:bond))
    celle_dun_autre = reservation(users(:martin_technique_paris), JOUR + 1)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: (JOUR + 1).to_s, user_id: users(:martin_technique_paris).id }

    assert Mouvement.exists?(la_mienne.id)
    assert Mouvement.exists?(celle_dun_autre.id)
  end

  test 'libere : une panne du même jour → elle n’est pas détruite (critique)' do
    en_panne = Mouvement.create!(tool: @outil, user: users(:administrateur_paris), état: :panne, date: JOUR)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert Mouvement.exists?(en_panne.id)
  end

  test 'libere : une réservation d’une autre organisation → rien n’est détruit (critique)' do
    ailleurs = Mouvement.create!(tool: tools(:camion), user: users(:manager_marseille), état: :réservé, date: JOUR)

    post libere_tool_mouvements_url(tool_id: tools(:camion).id),
         params: { date: JOUR.to_s, user_id: users(:manager_marseille).id }

    assert Mouvement.exists?(ailleurs.id)
  end
  # ==================== /TESTS CRITIQUES ====================

  test 'libere : aucune réservation ce jour-là → alerte, rien n’est détruit' do
    assert_no_difference('Mouvement.count') do
      post libere_tool_mouvements_url(tool_id: @outil.id),
           params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }
    end

    assert_equal "Il n'existe pas de réservation ce jour-là pour cet utilisateur.", flash[:alert]
  end

  test 'libere : sans paramètre → alerte au lieu d’une page blanche' do
    post libere_tool_mouvements_url(tool_id: @outil.id)

    assert_redirected_to tools_path
    assert_equal "Il n'existe pas de réservation ce jour-là pour cet utilisateur.", flash[:alert]
  end

  test 'libere : retour à la page d’où l’on vient, filtres compris' do
    reservation(users(:administrateur_paris))
    filtres = tools_url(search: 'cisaille', type: 'wrench', date: JOUR.to_s)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id },
         headers: { 'HTTP_REFERER' => filtres }

    assert_redirected_to filtres
  end

  test 'set_mouvement : un slug inconnu redirige sans planter' do
    get edit_mouvement_url(id: 'slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Mouvement introuvable', flash[:alert]
  end

  test 'set_mouvement : un slug inconnu ramène à la page précédente' do
    precedente = tools_url(search: 'cisaille')

    get edit_mouvement_url(id: 'slug-inexistant'), headers: { 'HTTP_REFERER' => precedente }

    assert_redirected_to precedente
    assert_equal 'Mouvement introuvable', flash[:alert]
  end

  def reservation(qui, jour = JOUR)
    Mouvement.create!(tool: @outil, user: qui, état: :réservé, date: jour)
  end
end
