# frozen_string_literal: true

require 'test_helper'

class MouvementsControllerTest < ActionDispatch::IntegrationTest
  JOUR = Date.new(2026, 6, 2)

  setup do
    @template_mouvement = mouvements(:mouvement_tondeuse)
    @outil = tools(:cisaille)
    sign_in users(:administrateur_paris)
  end

  # ==========================================================================
  # ============ TESTS CRITIQUES : réserver et libérer du matériel ===========
  # Parcours quotidien des agents. Une réservation perdue, ou celle d'un
  # collègue libérée par erreur, immobilise ou libère du matériel à tort.
  # ==========================================================================

  test 'réserver un outil crée une réservation à son nom' do
    assert_difference('Mouvement.count', 1) do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s }
    end

    mouvement = Mouvement.order(:id).last
    assert mouvement.réservé?
    assert_equal users(:administrateur_paris), mouvement.user
    assert_equal JOUR, mouvement.date
    assert_equal @outil, mouvement.tool
  end

  test 'un adhérent ne peut pas réserver de matériel' do
    sign_in users(:weil)

    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s }
    end
  end

  test "réserver l'outil d'une autre organisation est introuvable" do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: tools(:camion).id), params: { date: JOUR.to_s }
    end

    assert_response :not_found
  end

  test 'réserver avec une date illisible ne crée rien et prévient' do
    assert_no_difference('Mouvement.count') do
      post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: 'pas-une-date' }
    end

    assert_redirected_to tools_path
    assert_equal 'Date de réservation invalide.', flash[:alert]
  end

  # ÉPINGLAGE : rien n'empêche de réserver deux fois le même outil le même jour.
  # La grille n'en affiche qu'une. À inverser si le métier tranche.
  test 'réserver deux fois le même jour crée deux réservations' do
    assert_difference('Mouvement.count', 2) do
      2.times { post reserve_tool_mouvements_url(tool_id: @outil.id), params: { date: JOUR.to_s } }
    end
  end

  test 'libérer sa réservation la supprime' do
    mienne = reservation(users(:administrateur_paris))

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert_not Mouvement.exists?(mienne.id)
    assert_redirected_to tools_path
  end

  test 'libérer une réservation revient à la page filtrée' do
    reservation(users(:administrateur_paris))
    filtres = tools_url(search: 'cisaille', type: 'wrench', date: JOUR.to_s)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id },
         headers: { 'HTTP_REFERER' => filtres }

    assert_redirected_to filtres
  end

  test 'libérer une réservation inexistante revient à la page filtrée' do
    filtres = tools_url(search: 'cisaille', type: 'wrench', date: JOUR.to_s)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id },
         headers: { 'HTTP_REFERER' => filtres }

    assert_redirected_to filtres
  end

  test "un manager peut libérer la réservation d'un autre" do
    sign_in users(:hidalgo)
    celle_dun_autre = reservation(users(:bond))

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:bond).id }

    assert_not Mouvement.exists?(celle_dun_autre.id)
  end

  test "un agent ne peut pas libérer la réservation d'un autre" do
    sign_in users(:bond)
    celle_dun_autre = reservation(users(:martin_technique_paris))

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:martin_technique_paris).id }

    assert Mouvement.exists?(celle_dun_autre.id)
  end

  test "libérer une réservation inexistante prévient sans rien détruire" do
    assert_no_difference('Mouvement.count') do
      post libere_tool_mouvements_url(tool_id: @outil.id),
           params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }
    end

    assert_equal "Il n'existe pas de réservation ce jour-là pour cet utilisateur.", flash[:alert]
  end

  test 'libérer ne détruit pas une panne du même jour' do
    en_panne = Mouvement.create!(tool: @outil, user: users(:administrateur_paris), état: :panne, date: JOUR)

    post libere_tool_mouvements_url(tool_id: @outil.id),
         params: { date: JOUR.to_s, user_id: users(:administrateur_paris).id }

    assert Mouvement.exists?(en_panne.id)
  end

  test "libérer une réservation d'une autre organisation ne détruit rien" do
    ailleurs = Mouvement.create!(tool: tools(:camion), user: users(:manager_marseille), état: :réservé, date: JOUR)

    post libere_tool_mouvements_url(tool_id: tools(:camion).id),
         params: { date: JOUR.to_s, user_id: users(:manager_marseille).id }

    assert Mouvement.exists?(ailleurs.id)
  end

  # ÉPINGLAGE : sans paramètre, l'action ne rend rien (204, page blanche).
  test 'libérer sans paramètre ne répond rien' do
    post libere_tool_mouvements_url(tool_id: @outil.id)

    assert_response :no_content
  end

  # ==========================================================================
  # A. Suppression d'un mouvement
  # ==========================================================================

  # ÉPINGLAGE : destroy supprime tout le groupe créé au même instant (la paire
  # sortie + entrée), pas seulement le mouvement visé.
  test 'supprimer un mouvement supprime le groupe créé au même instant' do
    premier = reservation(users(:administrateur_paris))
    second = reservation(users(:administrateur_paris), JOUR + 1)
    second.update_columns(created_at: premier.created_at)

    delete mouvement_url(premier)

    assert_not Mouvement.exists?(premier.id)
    assert_not Mouvement.exists?(second.id)
  end

  test "supprimer un mouvement épargne ceux créés à un autre instant" do
    cible = reservation(users(:administrateur_paris))
    autre = reservation(users(:administrateur_paris), JOUR + 1)
    autre.update_columns(created_at: cible.created_at + 1.second)

    delete mouvement_url(cible)

    assert Mouvement.exists?(autre.id)
  end

  test "un agent ne peut pas supprimer la réservation d'un autre" do
    celle_dun_autre = reservation(users(:martin_technique_paris))
    sign_in users(:bond)

    delete mouvement_url(celle_dun_autre)

    assert Mouvement.exists?(celle_dun_autre.id)
  end

  test 'un agent peut supprimer sa propre réservation' do
    mienne = reservation(users(:bond))
    sign_in users(:bond)

    delete mouvement_url(mienne)

    assert_not Mouvement.exists?(mienne.id)
  end

  test 'un slug de mouvement inconnu redirige sans planter' do
    delete mouvement_url(id: 'slug-inexistant')

    assert_redirected_to root_path
  end

  test 'should get index' do
    get mouvements_url
    assert_response :success
  end

  test 'should get show' do
    get mouvement_url(@template_mouvement)
    assert_response :not_found # Page non activé
  end

  test 'should get new' do
    get new_mouvement_url
    assert_response :success
  end

  test 'should create mouvement' do
    assert_difference('Mouvement.count') do
      post mouvements_url,
           params: { mouvement: { tool_id: @template_mouvement.tool_id, état: @template_mouvement.état,
                                  date: DateTime.now } }
    end

    assert_redirected_to mouvements_path
  end

  # Création invalide SANS outil imposé (arrivée via /mouvements/new sans tool_id) :
  # le select doit rester affiché pour que l'utilisateur corrige son choix.
  test 'create invalide sans tool_id imposé : le select reste affiché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url,
           params: { mouvement: { tool_id: @template_mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'select[name=?]', 'mouvement[tool_id]'
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]', false
  end

  # Création invalide AVEC outil imposé (arrivée via new_mouvement_path(tool_id:)) :
  # le champ doit rester caché, l'outil ne devant pas être modifiable dans ce parcours.
  test 'create invalide avec tool_id imposé : le champ reste caché' do
    assert_no_difference('Mouvement.count') do
      post mouvements_url,
           params: { tool_id: @template_mouvement.tool_id,
                     mouvement: { tool_id: @template_mouvement.tool_id, état: 'réservé', date: '' } }
    end

    assert_response :unprocessable_content
    assert_select 'input[type=hidden][name=?]', 'mouvement[tool_id]'
    assert_select 'select[name=?]', 'mouvement[tool_id]', false
  end

  test 'should get edit' do
    get edit_mouvement_url(@template_mouvement)
    assert_response :success
  end

  test 'should update mouvement' do
    patch mouvement_url(@template_mouvement),
          params: { mouvement: { tool_id: @template_mouvement.tool_id, état: @template_mouvement.état,
                                 date: DateTime.now + 1.day } }
    assert_redirected_to mouvements_path
  end

  private

  def reservation(qui, jour = JOUR)
    Mouvement.create!(tool: @outil, user: qui, état: :réservé, date: jour)
  end

  # --- update : branches d'échec ---

  test 'update invalide réaffiche le formulaire en 422' do
    patch mouvement_url(@template_mouvement), params: { mouvement: { date: '' } }

    assert_response :unprocessable_content
    assert_not_nil @template_mouvement.reload.date
  end

  test 'update invalide en JSON renvoie les erreurs' do
    patch mouvement_url(@template_mouvement), params: { mouvement: { date: '' } }, as: :json

    assert_response :unprocessable_content
    assert_includes response.parsed_body.to_s, 'doit être rempli'
  end
end
