# frozen_string_literal: true

require 'test_helper'

# Filtre Services de l'index interventions (#311) : services du current_user
# présélectionnés au premier affichage, mais vidables — un administrateur qui
# retire ses services voit alors TOUTE son organisation (champ caché `service[]`).
# `comptabilite` est dans l'organisation de administrateur_paris (mairie_paris)
# mais PAS dans ses services → témoin « hors de mon périmètre personnel ».
class InterventionsIndexServiceFilterTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:administrateur_paris) # services : service_paris / informatique / technique
  end

  test 'admin : premier affichage → pré-filtré sur ses propres services' do
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url # aucun paramètre soumis

    assert_response :success
    # technique (un de ses services) visible, comptabilite (hors de ses services) non
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { count: 0 },
                  'par défaut, un service hors des siens ne doit pas apparaître'
  end

  test 'admin : filtre vidé (service[] soumis vide) → toute l\'organisation' do
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    # Le champ caché du formulaire soumet `service[]=` même quand rien n'est sélectionné
    get interventions_url, params: { service: [''] }

    assert_response :success
    # On voit TOUTE l'organisation : technique ET comptabilite
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { minimum: 1 },
                  'filtre vidé → un admin voit toute son organisation, y compris hors de ses services'
    # Et le menu ne présélectionne aucun service (placeholder « Tous les services »)
    assert_select "select[name='service[]'] option[selected]", false,
                  'filtre vidé → aucun service présélectionné'
  end

  test 'admin : choix explicite d\'un service → seulement ce service' do
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { minimum: 1 }
    # technique n'est pas demandé → non affiché
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { count: 0 }
  end

  test 'le formulaire fournit le champ caché service[] (permet de vider le filtre)' do
    get interventions_url

    assert_response :success
    assert_select "input[type=hidden][name='service[]']", { minimum: 1 },
                  'un champ caché service[] doit toujours être soumis pour distinguer vide/non-soumis'
  end
end
