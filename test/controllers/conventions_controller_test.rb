# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'
require_relative '../support/faux_ovh'

class ConventionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper
  include FauxModele
  include FauxOvh

  setup do
    travel_to Time.zone.local(2026, 10, 26, 12)
    brancher_faux_modele
    @admin = users(:administrateur_paris)
    @adherent = users(:patrick_adherent_paris)
    @service = services(:service_paris)
    @convention = conventions(:convention_paris)
    @analyse = conventions(:analyse_de_weil)
    @analyse_sans_adherent = conventions(:analyse_sans_adherent)
    @today = Date.current
    sign_in @admin
  end

  teardown do
    debrancher_faux_ovh
    debrancher_faux_modele
  end

  test 'la liste des conventions est affichée avec succès' do
    get conventions_url

    assert_response :success
  end

  test 'la liste ne retourne que les conventions validées, jamais une analyse' do
    get conventions_url

    assert_equal [@convention, conventions(:convention_sans_fin)], assigns(:conventions).to_a
  end

  test 'la recherche dans la liste ne retourne que les conventions correspondantes' do
    get conventions_url(search: 'inexistant.pdf')

    assert_response :success
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par adhérent ne retourne que les conventions de cet adhérent' do
    get conventions_url(adherent_id: @convention.user_id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(adherent_id: @adherent.id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par service ne retourne que les conventions de ce service' do
    get conventions_url(service_id: services(:informatique).id)
    assert_includes assigns(:conventions), @convention

    get conventions_url(service_id: services(:technique).id)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par plusieurs services retourne les conventions de l’un ou de l’autre' do
    get conventions_url(service_id: [services(:informatique).id, services(:comptabilite).id])
    assert_equal [@convention, conventions(:convention_sans_fin)], assigns(:conventions).to_a

    get conventions_url(service_id: [services(:technique).id, services(:comptabilite).id])
    assert_equal [conventions(:convention_sans_fin)], assigns(:conventions).to_a
  end

  test 'la liste filtrée par date ne retourne que les conventions actives à cette date' do
    get conventions_url(active_on: @today.beginning_of_year.to_s)
    assert_includes assigns(:conventions), @convention

    get conventions_url(active_on: (@today.beginning_of_year - 1.year).to_s)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'la liste filtrée par date retient une convention sans date de fin commencée avant cette date' do
    get conventions_url(active_on: '2030-05-06')

    assert_includes assigns(:conventions), conventions(:convention_sans_fin)
    assert_not_includes assigns(:conventions), @convention
  end

  test 'une convention est affichée avec succès' do
    get convention_url(@convention)

    assert_response :success
    assert_match @convention.user.nom_prénom, response.body
    assert_match @convention.service.nom, response.body
  end

  test 'une modification de convention apparaît dans son journal d’activité' do
    @convention.update!(mémo: 'Note de suivi')

    get convention_url(@convention)

    assert_response :success
    assert_select 'h2', text: 'Activité'
    assert_select 'td', text: /Note de suivi/
  end

  test 'une convention sans date de fin est affichée avec succès' do
    sans_fin = conventions(:convention_sans_fin)

    get convention_url(sans_fin)

    assert_response :success
    assert_match sans_fin.service.nom, response.body
  end

  test 'ce que l’IA a lu d’une analyse est affiché, chaque valeur à côté de la ligne du document qui la donne' do
    get convention_url(@analyse)

    assert_response :success
    assert_dom 'a[href=?]', user_path(users(:weil)), text: 'Weil Ariel'
    assert_dom 'span', text: 'Technique'
    assert_dom 'div', text: '350 h'
    assert_dom 'div', text: /\A1 janvier 2025\s+→\s+—\z/
    assert_dom 'p', text: '« et Ariel Weil, adhérent »'
    assert_dom 'p', text: '« un volume annuel de 350 heures »', count: 2
    assert_dom 'p', text: /\[incertain : 16\] décembre 2024.*extrait introuvable dans le texte/m
  end

  test 'une date de début que le document ne donnait pas est signalée comme déduite' do
    get convention_url(@analyse_sans_adherent)

    assert_dom 'span', text: '⚠ Déduit : début repris de la date de signature'
  end

  test 'une modification d’analyse apparaît dans son journal d’activité' do
    @analyse.update!(mémo: 'Relu avec la commune')

    get convention_url(@analyse)

    assert_select 'td', text: /Relu avec la commune/
  end

  test 'un adhérent à confirmer est signalé à l’administrateur, avec le lien pour le créer' do
    get convention_url(@analyse_sans_adherent)

    assert_dom 'div', text: /⚠ Adhérent à confirmer — lu : Beaumont\.\s+Créer l'adhérent/
    assert_dom 'a[href=?]', admin_create_new_user_path(convention_id: @analyse_sans_adherent.slug), text: "Créer l'adhérent"
  end

  test 'un adhérent à confirmer est signalé au manager, renvoyé vers un administrateur' do
    sign_in users(:hidalgo)

    get convention_url(@analyse_sans_adherent)

    assert_dom 'div', text: /⚠ Adhérent à confirmer — lu : Beaumont\.\s+S'il n'existe pas, demandez à un administrateur de le créer\./
    assert_dom 'a', text: "Créer l'adhérent", count: 0
  end

  test 'un adhérent reconnu n’est pas signalé' do
    get convention_url(@analyse)

    assert_dom 'span', text: /Adhérent à confirmer/, count: 0
  end

  test 'le résumé et le mémo d’une analyse sont affichés' do
    get convention_url(@analyse_sans_adherent)

    assert_dom 'p', text: 'La Communauté de Communes met ses services technique et informatique à la disposition de la commune de Beaumont.'
    assert_dom 'p', text: /Durée : Elle est conclue pour une durée de trois ans\.\s+Tarif : Le coût unitaire est fixé à 34 euros par heure\./
  end

  test 'la raison d’une analyse en échec est affichée' do
    get convention_url(conventions(:analyse_en_echec))

    assert_dom 'p', text: "L'analyse a échoué"
    assert_dom 'p', text: 'IA injoignable'
  end

  test 'une analyse en attente est affichée avec succès' do
    get convention_url(conventions(:analyse_en_attente))

    assert_response :success
    assert_dom 'button', text: 'Valider la convention', count: 0
  end

  test 'la validation d’une analyse complète est proposée' do
    get convention_url(@analyse)

    assert_dom 'form[action=?] button:not([disabled])', valider_convention_path(@analyse), text: 'Valider la convention'
  end

  test 'la validation d’une analyse incomplète est inactive, avec ce qui manque' do
    get convention_url(@analyse_sans_adherent)

    assert_dom 'button[disabled][title=?]', 'Adhérent doit être rempli(e)', text: 'Valider la convention'
    assert_dom 'li', text: 'Adhérent doit être rempli(e)'
  end

  test 'la validation est inactive pour un manager sur un service qu’il ne gère pas, avec la raison' do
    sign_in users(:hidalgo)

    get convention_url(conventions(:analyse_hors_des_services_de_hidalgo))

    assert_dom 'button[disabled][title=?]', "Seul un administrateur peut valider une convention d'un service que vous ne gérez pas.",
               text: 'Valider la convention'
  end

  test 'la convention existante est proposée quand l’analyse la répète' do
    get convention_url(conventions(:analyse_deja_conventionnee))

    assert_dom 'li', text: 'Cet adhérent a déjà une convention pour ce service dans cette période.'
    assert_dom 'a[href=?]', convention_path(@convention), text: 'Voir la convention existante'
  end

  test 'le formulaire de création est affiché avec succès' do
    get new_convention_url

    assert_response :success
  end

  test 'l’adhérent passé en paramètre est préchargé dans le formulaire de création' do
    get new_convention_url(adherent_id: @adherent.slug)

    assert_response :success
    assert_equal @adherent, assigns(:convention).user
  end

  test 'un manager ne se voit proposer que les adhérents de ses services' do
    sign_in users(:hidalgo)

    get new_convention_url

    assert_response :success
    assert_includes assigns(:adherents), users(:weil)
    assert_not_includes assigns(:adherents), users(:adherent_marseille)
  end

  test 'la date de début du formulaire de création est préremplie au 1ᵉʳ janvier de l’année en cours' do
    get new_convention_url

    assert_equal Date.new(2026, 1, 1), assigns(:convention).date_début
  end

  test 'une convention est créée lorsque les paramètres sont valides' do
    assert_difference('Convention.count') do
      post conventions_url, params: { convention: {
        user_id: @adherent.id,
        service_id: @service.id,
        date_début: @today.to_s,
        date_fin_prévue: (@today + 1.year).to_s,
        heures_conventionnees: 100
      } }
    end

    assert_redirected_to conventions_path
  end

  test 'une convention saisie à la main est validée dès sa création' do
    post conventions_url, params: { convention: params_valides }

    assert_predicate @adherent.conventions.last, :validé?
  end

  test 'une convention n’est pas créée sans heures conventionnées' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(heures_conventionnees: '') }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée avec zéro heure conventionnée' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(heures_conventionnees: 0) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque l’adhérent en a déjà une pour ce service sur la période' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(
        user_id: users(:weil).id, service_id: services(:informatique).id
      ) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque la date de fin est antérieure à la date de début' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(
        date_fin_prévue: (@today - 1.month).to_s
      ) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention n’est pas créée lorsque le service n’est pas un service de l’adhérent' do
    assert_no_difference -> { Convention.count } do
      post conventions_url, params: { convention: params_valides.merge(service_id: services(:informatique).id) }
    end

    assert_response :unprocessable_content
  end

  test 'une convention est créée sans date de fin' do
    assert_difference('Convention.count') do
      post conventions_url, params: { convention: params_valides.merge(date_fin_prévue: '') }
    end

    assert_redirected_to conventions_path
    assert_nil @adherent.conventions.last.date_fin_prévue
  end

  test 'une convention est créée avec sa date de signature et son résumé' do
    post conventions_url, params: { convention: params_valides.merge(date_signature: '2025-12-15', résumé: 'Mise à disposition du service pour cent heures.') }

    convention = @adherent.conventions.last
    assert_equal [Date.new(2025, 12, 15), 'Mise à disposition du service pour cent heures.'], [convention.date_signature, convention.résumé]
  end

  test 'le formulaire de modification est affiché avec succès' do
    get edit_convention_url(@convention)

    assert_response :success
  end

  test 'le formulaire de modification d’une analyse laisse choisir l’adhérent et le service' do
    get edit_convention_url(@analyse)

    assert_dom 'select[name=?] option[selected][value=?]', 'convention[user_id]', users(:weil).id.to_s
    assert_dom 'select[name=?] option[selected][value=?]', 'convention[service_id]', services(:technique).id.to_s
  end

  test 'un service lu que le formulaire ne propose pas pour cet adhérent est laissé à choisir' do
    get edit_convention_url(conventions(:analyse_sur_un_service_hors_de_l_adherent))

    assert_equal users(:weil), assigns(:convention).user
    assert_nil assigns(:convention).service
    assert_dom 'select[name=?] option[selected]', 'convention[service_id]', count: 0
  end

  test 'un adhérent lu hors des services du manager est laissé à choisir, son service aussi' do
    sign_in users(:hidalgo)

    get edit_convention_url(conventions(:analyse_hors_des_services_de_hidalgo))

    assert_nil assigns(:convention).user
    assert_nil assigns(:convention).service
    assert_equal 60, assigns(:convention).heures_conventionnees
  end

  test 'une convention perd sa date de fin lorsqu’elle est vidée à la modification' do
    patch convention_url(@convention), params: { convention: { date_fin_prévue: '' } }

    assert_redirected_to conventions_path
    assert_nil @convention.reload.date_fin_prévue
  end

  test 'une convention n’est pas modifiée avec zéro heure conventionnée' do
    patch convention_url(@convention), params: { convention: { heures_conventionnees: 0 } }

    assert_response :unprocessable_content
    assert_equal 100, @convention.reload.heures_conventionnees
  end

  test 'une analyse modifiée reste à valider et ramène à sa page' do
    patch convention_url(@analyse_sans_adherent), params: { convention: { user_id: users(:weil).id } }

    assert_redirected_to convention_path(@analyse_sans_adherent)
    assert_equal [users(:weil), Convention::ANALYSE], [@analyse_sans_adherent.reload.user, @analyse_sans_adherent.workflow_state]
  end

  test 'une convention est supprimée' do
    assert_difference('Convention.count', -1) do
      delete convention_url(@convention)
    end

    assert_redirected_to conventions_path
  end

  test 'une analyse supprimée ramène à la liste des analyses' do
    assert_difference('Convention.count', -1) do
      delete convention_url(@analyse)
    end

    assert_redirected_to analyses_conventions_path
  end

  test 'les services d’un adhérent sont retournés en JSON' do
    get services_for_adherent_conventions_url(adherent_id: @adherent.id)

    assert_response :success
    assert_includes response.parsed_body.map { |service| service['nom'] }, @service.nom
  end

  test 'aucun service n’est retourné pour un adhérent d’une autre organisation' do
    get services_for_adherent_conventions_url(adherent_id: users(:adherent_marseille).id)

    assert_response :success
    assert_empty response.parsed_body
  end

  test 'une analyse en échec est relancée' do
    analyse = conventions(:analyse_en_echec)

    assert_enqueued_with(job: AnalyserConventionJob, args: [analyse]) do
      post relancer_convention_url(analyse)
    end

    assert_redirected_to analyses_conventions_path
    assert_equal 'Analyse relancée.', flash[:notice]
    assert_equal [Convention::EN_ATTENTE, {}], [analyse.reload.workflow_state, analyse.analyse]
  end

  test 'une analyse qui n’est pas en échec n’est pas relancée' do
    assert_no_enqueued_jobs only: AnalyserConventionJob do
      post relancer_convention_url(@analyse)
    end

    assert_redirected_to analyses_conventions_path
    assert_predicate @analyse.reload, :analysé?
  end

  test 'sans IA configurée, une analyse en échec n’est pas relancée' do
    ENV['LLM_HOST'] = nil
    analyse = conventions(:analyse_en_echec)

    assert_no_enqueued_jobs only: AnalyserConventionJob do
      post relancer_convention_url(analyse)
    end

    assert_predicate analyse.reload, :échec?
  end

  test 'une analyse complète est validée et reçoit sa référence' do
    patch valider_convention_url(@analyse)

    assert_redirected_to convention_path(@analyse)
    assert_equal 'Convention validée.', flash[:notice]
    assert_predicate @analyse.reload, :validé?
    assert_match(/\ACONV-2026-\d+\z/, @analyse.ref)
  end

  test 'une analyse incomplète n’est pas validée, et la raison est donnée' do
    patch valider_convention_url(@analyse_sans_adherent)

    assert_redirected_to convention_path(@analyse_sans_adherent)
    assert_equal 'Convention non validée : Adhérent doit être rempli(e)', flash[:alert]
    assert_predicate @analyse_sans_adherent.reload, :analysé?
  end

  test 'une analyse en attente ne peut pas être validée' do
    analyse = conventions(:analyse_en_attente)

    patch valider_convention_url(analyse)

    assert_redirected_to convention_path(analyse)
    assert_equal 'Cette convention ne peut pas être validée.', flash[:alert]
    assert_predicate analyse.reload, :en_attente?
  end

  test 'la liste des analyses est affichée avec succès' do
    get analyses_conventions_url

    assert_response :success
  end

  test 'la liste des analyses ne retourne aucune convention validée' do
    get analyses_conventions_url

    assert_equal dix_analyses_les_plus_recentes, assigns(:analyses).to_a
  end

  test 'la liste range en tête l’analyse mise à jour le plus récemment' do
    conventions(:analyse_deja_conventionnee).update!(mémo: 'Relue')

    get analyses_conventions_url

    assert_equal [conventions(:analyse_deja_conventionnee)] + dix_analyses_les_plus_recentes.first(9), assigns(:analyses).to_a
  end

  test 'la ligne d’une analyse mène à sa page et donne son adhérent, son service et ses heures' do
    get analyses_conventions_url

    assert_dom "tr##{dom_id(@analyse)}" do
      assert_dom 'a[href=?]', convention_path(@analyse), text: 'Ouvrir'
      assert_dom 'td', text: 'exemple.pdf'
      assert_dom 'td', text: 'Weil Ariel'
      assert_dom 'td', text: 'Technique'
      assert_dom 'td', text: '350 h'
    end
  end

  test 'la ligne d’une analyse dont l’adhérent est à confirmer le signale avec le nom lu' do
    get analyses_conventions_url

    assert_dom "tr##{dom_id(@analyse_sans_adherent)} td", text: '⚠ À confirmer : Beaumont'
  end

  test 'la ligne d’une analyse en échec en donne la raison' do
    get analyses_conventions_url

    assert_dom "tr##{dom_id(conventions(:analyse_en_echec))} td", text: 'IA injoignable'
  end

  # ==================== TESTS CRITIQUES ====================
  # Les listes des filtres dérivent des services de l'utilisateur : ni service ni adhérent d'une autre organisation n'y
  # entre, et un manager n'y trouve que les siens.
  test 'la liste des analyses propose à un administrateur les services de son organisation et leurs adhérents pour filtrer (critique)' do
    get analyses_conventions_url

    assert_equal organisations(:mairie_paris).services.sort_by(&:id), assigns(:services).sort_by(&:id)
    assert_includes assigns(:adherents), users(:george_lucas)
    assert_not_includes assigns(:adherents), users(:adherent_marseille)
  end

  test 'la liste des analyses ne propose à un manager que ses services et leurs adhérents pour filtrer (critique)' do
    sign_in users(:hidalgo)

    get analyses_conventions_url

    assert_equal [services(:informatique), services(:service_paris), services(:technique)].sort_by(&:id), assigns(:services).sort_by(&:id)
    assert_includes assigns(:adherents), users(:weil)
    assert_not_includes assigns(:adherents), users(:george_lucas)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la liste des analyses filtrée par adhérent ne retourne que celles qui le nomment' do
    get analyses_conventions_url(adherent_id: users(:weil).id)

    assert_equal [@analyse, conventions(:analyse_deja_conventionnee), conventions(:analyse_sur_un_service_hors_de_l_adherent)],
                 assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée par un adhérent inconnu ou malformé n’en retourne aucune' do
    get analyses_conventions_url(adherent_id: 0)
    assert_empty assigns(:analyses)

    get analyses_conventions_url(adherent_id: 'abc')
    assert_empty assigns(:analyses)
  end

  test 'la liste des analyses filtrée par service ne retourne que celles de ce service' do
    get analyses_conventions_url(service_id: [services(:comptabilite).id])

    assert_equal [conventions(:analyse_hors_des_services_de_hidalgo)], assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée par plusieurs services retourne celles de l’un ou de l’autre' do
    get analyses_conventions_url(service_id: [services(:comptabilite).id, services(:secretariat).id])

    assert_equal [conventions(:analyse_hors_des_services_de_hidalgo), conventions(:analyse_sur_un_service_hors_de_l_adherent)],
                 assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée par un service inconnu ou malformé n’en retourne aucune' do
    get analyses_conventions_url(service_id: [0])
    assert_empty assigns(:analyses)

    get analyses_conventions_url(service_id: ['abc'])
    assert_empty assigns(:analyses)
  end

  test 'la liste des analyses filtrée par état ne retourne que celles dans cet état' do
    get analyses_conventions_url(etat: Convention::ECHEC)

    assert_equal [conventions(:analyse_en_echec)], assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée par un état inconnu, ou par l’état validé, n’en retourne aucune' do
    get analyses_conventions_url(etat: 'inconnu')
    assert_empty assigns(:analyses)

    get analyses_conventions_url(etat: Convention::VALIDE)
    assert_empty assigns(:analyses)
  end

  test 'la liste des analyses filtrée depuis une date ne retourne que celles déposées ce jour-là ou après' do
    get analyses_conventions_url(du: '2026-10-06')

    assert_equal [conventions(:analyse_d_un_compte_desactive), conventions(:analyse_de_l_administrateur_paris),
                  conventions(:analyse_de_manager_paris)], assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée jusqu’à une date ne retourne que celles déposées ce jour-là ou avant' do
    get analyses_conventions_url(au: '2026-09-29')

    assert_equal [conventions(:analyse_deja_conventionnee), conventions(:analyse_citant_un_service_de_marseille),
                  conventions(:analyse_sur_un_service_hors_de_l_adherent)], assigns(:analyses).to_a
  end

  test 'la liste des analyses filtrée sur une période ne retourne que celles déposées entre ses deux dates' do
    get analyses_conventions_url(du: '2026-10-01', au: '2026-10-02')

    assert_equal [conventions(:analyse_hors_des_services_de_hidalgo), conventions(:analyse_de_patrick)], assigns(:analyses).to_a
  end

  test 'une date de filtre malformée ne filtre pas la liste des analyses' do
    get analyses_conventions_url(du: 'abc', au: '2026-02-31')

    assert_response :success
    assert_equal dix_analyses_les_plus_recentes, assigns(:analyses).to_a
  end

  test 'le formulaire de filtres des analyses soumis vide ne filtre pas la liste' do
    get analyses_conventions_url(adherent_id: '', service_id: [''], etat: '', du: '', au: '')

    assert_equal dix_analyses_les_plus_recentes, assigns(:analyses).to_a
  end

  test 'les filtres choisis restent affichés dans le formulaire des analyses' do
    get analyses_conventions_url(adherent_id: users(:weil).id, service_id: [services(:technique).id], etat: Convention::ANALYSE,
                                 du: '2026-10-01', au: '2026-10-31')

    assert_dom 'select#adherent_id option[selected][value=?]', users(:weil).id.to_s
    assert_dom 'select#service_id option[selected][value=?]', services(:technique).id.to_s
    assert_dom 'select#etat option[selected][value=?]', Convention::ANALYSE
    assert_dom 'input#du[value=?]', '2026-10-01'
    assert_dom 'input#au[value=?]', '2026-10-31'
  end

  test 'la liste des analyses annonce une IA en pause, réveillée au dépôt et remise en pause après les analyses' do
    brancher_faux_ovh('SHELVED_OFFLOADED')

    get analyses_conventions_url

    assert_dom '#etat_ia p', text: "L'IA est en pause"
    assert_dom '#etat_ia p', text: 'Un dépôt la réveille : comptez environ 30 minutes ; elle se remettra en pause dès la fin des analyses.'
  end

  test 'la liste des analyses annonce une IA qui démarre' do
    brancher_faux_ovh('UNSHELVING')

    get analyses_conventions_url

    assert_dom '#etat_ia p', text: "L'IA démarre"
    assert_dom '#etat_ia p', text: "Les documents sont en attente d'analyse."
  end

  test 'la liste des analyses n’annonce rien d’une IA active' do
    brancher_faux_ovh('ACTIVE')

    get analyses_conventions_url

    assert_dom '#etat_ia p', count: 0
  end

  test 'la liste des analyses annonce une IA qui se met en pause, et déconseille de déposer d’ici là' do
    brancher_faux_ovh('SHELVING')

    get analyses_conventions_url

    assert_dom '#etat_ia p', text: "L'IA se met en pause"
    assert_dom '#etat_ia p', text: "Attendez qu'elle le soit pour déposer : un document déposé maintenant passerait en échec."
  end

  test 'la liste des analyses donne l’état d’une IA ni en pause, ni active, ni en train de démarrer' do
    brancher_faux_ovh('SHUTOFF')

    get analyses_conventions_url

    assert_dom '#etat_ia p', text: "L'IA est indisponible pour le moment"
    assert_dom '#etat_ia p', text: 'État signalé par OVH : « SHUTOFF ».'
  end

  test 'la liste des analyses n’annonce rien de l’IA sur une instance qui ne la pilote pas' do
    get analyses_conventions_url

    assert_dom '#etat_ia p', count: 0
  end

  test 'la liste des analyses s’affiche sans rien annoncer de l’IA quand l’API OVH ne répond pas (critique)' do
    brancher_faux_ovh('ACTIVE')
    stub_request(:get, INSTANCE_OVH).to_timeout

    get analyses_conventions_url

    assert_response :success
    assert_dom '#etat_ia p', count: 0
  end

  test 'sans IA configurée, la liste des analyses renvoie aux conventions avec un message' do
    ENV['LLM_HOST'] = nil

    get analyses_conventions_url

    assert_redirected_to conventions_path
    assert_equal "L'analyse par l'IA n'est pas configurée sur cette instance.", flash[:alert]
  end

  test 'un document déposé devient une convention en attente d’analyse au nom du déposant, mise en file' do
    assert_difference 'Convention.count', 1 do
      assert_enqueued_jobs 1, only: AnalyserConventionJob do
        post analyses_conventions_url, params: { convention: { document: ['', fixture_file_upload('exemple.pdf', 'application/pdf')] } }
      end
    end

    assert_redirected_to analyses_conventions_path
    assert_equal "1 document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué.", flash[:notice]
    assert_equal [@admin, Convention::EN_ATTENTE], Convention.order(:id).last.then { |convention| [convention.deposant, convention.workflow_state] }
  end

  test 'plusieurs documents déposés donnent chacun une convention à analyser' do
    documents = [fixture_file_upload('exemple.pdf', 'application/pdf'), fixture_file_upload('exemple.pdf', 'application/pdf')]

    assert_difference 'Convention.count', 2 do
      assert_enqueued_jobs 2, only: AnalyserConventionJob do
        post analyses_conventions_url, params: { convention: { document: documents } }
      end
    end

    assert_equal "2 document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué.", flash[:notice]
  end

  test 'un dépôt sans document est refusé avec un message' do
    assert_no_difference 'Convention.count' do
      post analyses_conventions_url, params: { convention: { document: [''] } }
    end

    assert_redirected_to analyses_conventions_path
    assert_equal 'Aucun document déposé.', flash[:alert]
  end

  test 'un document qui n’est pas un PDF est refusé, les autres sont gardés' do
    documents = [fixture_file_upload('page_numerisee.png', 'image/png'), fixture_file_upload('exemple.pdf', 'application/pdf')]

    assert_difference 'Convention.count', 1 do
      post analyses_conventions_url, params: { convention: { document: documents } }
    end

    assert_equal 'page_numerisee.png : Document format non pris en charge (image/png)', flash[:alert]
    assert_equal "1 document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué.", flash[:notice]
  end

  test 'un dépôt sur une IA en pause ne la réveille pas lui-même : l’analyse mise en file s’en charge (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')

    assert_enqueued_jobs 1, only: AnalyserConventionJob do
      post analyses_conventions_url, params: { convention: { document: [fixture_file_upload('exemple.pdf', 'application/pdf')] } }
    end

    assert_not_requested(:post, "#{INSTANCE_OVH}/unshelve")
  end

  test 'sans IA configurée, un dépôt est renvoyé aux conventions sans rien enregistrer' do
    ENV['LLM_HOST'] = nil

    assert_no_difference 'Convention.count' do
      post analyses_conventions_url, params: { convention: { document: [fixture_file_upload('exemple.pdf', 'application/pdf')] } }
    end

    assert_redirected_to conventions_path
  end

  test 'un slug de convention inconnu redirige sans planter' do
    get convention_url(id: 'slug-qui-n-existe-pas')

    assert_redirected_to root_path
    assert_equal 'Convention introuvable', flash[:alert]
  end

  private

  def params_valides
    { user_id: @adherent.id, service_id: @service.id, date_début: @today.to_s,
      date_fin_prévue: (@today + 1.year).to_s, heures_conventionnees: 100 }
  end

  # La première page de la liste des analyses d'un administrateur, sans filtre ni tri demandé.
  def dix_analyses_les_plus_recentes
    %i[analyse_d_un_compte_desactive analyse_de_l_administrateur_paris analyse_de_manager_paris analyse_en_attente analyse_en_echec
       analyse_de_weil analyse_hors_des_services_de_hidalgo analyse_de_patrick analyse_sans_adherent analyse_deja_conventionnee]
      .map { |analyse| conventions(analyse) }
  end
end
