# frozen_string_literal: true

require 'test_helper'

class MouvementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @mouvement = mouvements(:mouvement_tondeuse)
    @outil = tools(:cisaille)
    sign_in users(:administrateur_paris)
  end

  # Jour de référence des réservations, hors de toute fixture.
  JOUR = Date.new(2026, 6, 2)

  test 'la liste des mouvements est affichée avec succès' do
    get mouvements_url

    assert_response :success
  end

  test 'la liste filtrée par utilisateur ne retourne que les mouvements de cet utilisateur' do
    la_mienne = reservation(users(:administrateur_paris))
    celle_dun_autre = reservation(users(:bond))

    get mouvements_url, params: { user_ids: [users(:administrateur_paris).id] }

    assert_includes assigns(:mouvements), la_mienne
    assert_not_includes assigns(:mouvements), celle_dun_autre
  end

  test 'la liste filtrée par date ne retourne que les mouvements de ce jour-là' do
    ce_jour_la = reservation(users(:administrateur_paris))
    la_veille = reservation(users(:administrateur_paris), JOUR - 1)

    get mouvements_url, params: { date: JOUR.to_s }

    assert_includes assigns(:mouvements), ce_jour_la
    assert_not_includes assigns(:mouvements), la_veille
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_mouvement_url

    assert_response :success
  end

  test 'un mouvement est créé lorsque les paramètres sont valides' do
    assert_difference('Mouvement.count') do
      post mouvements_url, params: { mouvement: { tool_id: @mouvement.tool_id, état: @mouvement.état,
                                                  date: DateTime.now } }
    end

    assert_redirected_to mouvements_path
  end

  # Arrivée via /mouvements/new sans tool_id : le select doit rester affiché pour
  # que l'utilisateur corrige son choix.
  test 'un mouvement invalide sans outil imposé laisse le choix de l’outil affiché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url, params: { mouvement: { tool_id: @mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'select[name=?]', 'mouvement[tool_id]'
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]', false
  end

  # Arrivée via new_mouvement_path(tool_id:) : l'outil ne doit pas être modifiable
  # dans ce parcours, le champ reste donc caché.
  test 'un mouvement invalide avec un outil imposé garde l’outil en champ caché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url, params: { tool_id: @mouvement.tool_id,
                                     mouvement: { tool_id: @mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]'
    assert_select 'select[name=?]', 'mouvement[tool_id]', false
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_mouvement_url(@mouvement)

    assert_response :success
  end

  test 'un mouvement est modifié lorsque les paramètres sont valides' do
    patch mouvement_url(@mouvement), params: { mouvement: { tool_id: @mouvement.tool_id, état: @mouvement.état,
                                                            date: DateTime.now + 1.day } }

    assert_redirected_to mouvements_path
  end

  test 'un mouvement dont la date est vidée n’est pas modifié' do
    patch mouvement_url(@mouvement), params: { mouvement: { date: '' } }

    assert_response :unprocessable_content
    assert_not_nil @mouvement.reload.date
  end

  # Parcours quotidien des agents : une réservation perdue, ou celle d'un collègue
  # libérée par erreur, immobilise ou libère du matériel à tort.

  # ==================== TESTS CRITIQUES ====================

  test 'réserver un outil crée une réservation à son nom pour la date demandée (critique)' do
    assert_difference('Mouvement.count', 1) do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s }
    end

    mouvement = Mouvement.order(:id).last
    assert mouvement.réservé?
    assert_equal users(:administrateur_paris), mouvement.user
    assert_equal JOUR, mouvement.date
    assert_equal @outil, mouvement.tool
  end

  test 'un outil d’une autre organisation est introuvable et ne peut pas être réservé (critique)' do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: tools(:camion).id), params: { date: JOUR.to_s }
    end

    assert_response :not_found
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une réservation à une date illisible n’est pas créée et déclenche une alerte' do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: 'pas-une-date' }
    end

    assert_redirected_to tools_path
    assert_equal 'Date de réservation invalide.', flash[:alert]
  end

  # ÉPINGLAGE : rien n'empêche de réserver deux fois le même outil le même jour.
  # La grille n'en affiche qu'une. À inverser si le métier tranche.
  test 'réserver deux fois le même outil le même jour crée deux réservations' do
    assert_difference('Mouvement.count', 2) do
      2.times { post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s } }
    end
  end

  # ==================== TESTS CRITIQUES ====================

  test 'un administrateur peut libérer sa propre réservation (critique)' do
    mienne = reservation(users(:administrateur_paris))

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert_not Mouvement.exists?(mienne.id)
    assert_redirected_to tools_path
  end

  test 'un manager peut libérer la réservation d’un autre utilisateur (critique)' do
    sign_in users(:hidalgo)
    celle_dun_autre = reservation(users(:bond))

    post libere_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s, user_id: users(:bond).id }

    assert_not Mouvement.exists?(celle_dun_autre.id)
  end

  test 'un agent peut libérer sa propre réservation (critique)' do
    sign_in users(:bond)
    la_mienne = reservation(users(:bond))

    post libere_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s, user_id: users(:bond).id }

    assert_not Mouvement.exists?(la_mienne.id)
  end

  # La substitution silencieuse d'un `user_id` forgé par celui du current_user
  # libérerait la réservation de l'agent au lieu de refuser la requête.
  test 'une requête forgée par un agent sur la réservation d’un autre ne détruit aucune réservation (critique)' do
    sign_in users(:bond)
    la_mienne = reservation(users(:bond))
    celle_dun_autre = reservation(users(:martin_technique_paris), JOUR + 1)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: (JOUR + 1).to_s, user_id: users(:martin_technique_paris).id }

    assert Mouvement.exists?(la_mienne.id)
    assert Mouvement.exists?(celle_dun_autre.id)
  end

  test 'libérer un outil ne détruit pas une panne déclarée le même jour (critique)' do
    en_panne = Mouvement.create!(tool: @outil, user: users(:administrateur_paris), état: :panne, date: JOUR)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert Mouvement.exists?(en_panne.id)
  end

  test 'une réservation d’une autre organisation ne peut pas être libérée (critique)' do
    ailleurs = Mouvement.create!(tool: tools(:camion), user: users(:manager_marseille), état: :réservé, date: JOUR)

    post libere_tool_mouvements_url(tool_id: tools(:camion).id),
         params: { date: JOUR.to_s, user_id: users(:manager_marseille).id }

    assert Mouvement.exists?(ailleurs.id)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'libérer un outil sans réservation ce jour-là déclenche une alerte sans rien détruire' do
    assert_no_difference('Mouvement.count') do
      post libere_tool_mouvements_url(tool_id: @outil.id),
           params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }
    end

    assert_equal "Il n'existe pas de réservation ce jour-là pour cet utilisateur.", flash[:alert]
  end

  test 'libérer un outil sans paramètre déclenche une alerte au lieu d’une page blanche' do
    post libere_tool_mouvements_url(tool_id: @outil.id)

    assert_redirected_to tools_path
    assert_equal "Il n'existe pas de réservation ce jour-là pour cet utilisateur.", flash[:alert]
  end

  test 'libérer un outil ramène à la page d’origine, filtres compris' do
    reservation(users(:administrateur_paris))
    filtres = tools_url(search: 'cisaille', type: 'wrench', date: JOUR.to_s)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id },
         headers: { 'HTTP_REFERER' => filtres }

    assert_redirected_to filtres
  end

  test 'un slug de mouvement inconnu redirige sans planter' do
    get edit_mouvement_url(id: 'slug-inexistant')

    assert_redirected_to root_path
    assert_equal 'Mouvement introuvable', flash[:alert]
  end

  test 'un slug de mouvement inconnu ramène à la page précédente' do
    precedente = tools_url(search: 'cisaille')

    get edit_mouvement_url(id: 'slug-inexistant'), headers: { 'HTTP_REFERER' => precedente }

    assert_redirected_to precedente
    assert_equal 'Mouvement introuvable', flash[:alert]
  end

  private

  def reservation(qui, jour = JOUR)
    Mouvement.create!(tool: @outil, user: qui, état: :réservé, date: jour)
  end
end
