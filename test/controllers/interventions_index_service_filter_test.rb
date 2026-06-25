# frozen_string_literal: true

require 'test_helper'

# Filtre Services de l'index interventions (#309/#311) :
#  - ADMIN : voit TOUTES les interventions de son organisation par défaut, filtre
#    vide (services non présélectionnés) ;
#  - MANAGER : filtre vide par défaut, voit tous les records de SES services (non
#    présélectionnés) ; filtre masqué s'il n'a qu'un seul service.
# `comptabilite` est dans l'organisation de administrateur_paris (mairie_paris)
# mais PAS dans ses services → témoin « hors de mon périmètre personnel ».
class InterventionsIndexServiceFilterTest < ActionDispatch::IntegrationTest
  # --- Administrateur --------------------------------------------------------

  test 'admin : premier affichage → voit toute l\'organisation, rien de présélectionné' do
    sign_in users(:administrateur_paris)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url # aucun paramètre soumis

    assert_response :success
    # technique (un de ses services) ET comptabilite (hors de ses services) visibles
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { minimum: 1 },
                  'un admin voit par défaut toute son organisation, y compris hors de ses services'
    assert_select "select[name='service[]'] option[selected]", false,
                  'aucun service ne doit être présélectionné par défaut pour un admin'
  end

  test 'admin : choix explicite d\'un service → seulement ce service' do
    sign_in users(:administrateur_paris)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id)

    get interventions_url, params: { service: [services(:comptabilite).id] }

    assert_response :success
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { minimum: 1 }
    # technique n'est pas demandé → non affiché
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { count: 0 }
  end

  test 'le formulaire fournit le champ caché service[] (permet de vider le filtre)' do
    sign_in users(:administrateur_paris)

    get interventions_url

    assert_response :success
    assert_select "input[type=hidden][name='service[]']", { minimum: 1 },
                  'un champ caché service[] doit toujours être soumis pour distinguer vide/non-soumis'
  end

  # --- Manager ---------------------------------------------------------------

  test 'manager : premier affichage → filtre vide, voit tous ses services' do
    sign_in users(:hidalgo) # services : service_paris / informatique / technique
    get interventions_url

    assert_response :success
    # ses interventions (service technique) sont visibles…
    assert_select 'a[href=?]', intervention_path(interventions(:nouvelle_intervention)), { minimum: 1 }
    # …sans aucun service présélectionné
    assert_select "select[name='service[]'] option[selected]", false,
                  'un manager ne doit avoir aucun service présélectionné par défaut'
  end

  test 'manager : un service hors de son périmètre n\'apparaît jamais (même filtre vide)' do
    sign_in users(:hidalgo)
    hors_perimetre = interventions(:tonte_locaux)
    hors_perimetre.update_columns(service_id: services(:comptabilite).id) # hors des services de hidalgo

    get interventions_url

    assert_response :success
    assert_select 'a[href=?]', intervention_path(hors_perimetre), { count: 0 },
                  'un manager ne voit que ses propres services, jamais toute l\'organisation'
  end

  test 'manager mono-service : le filtre service est masqué' do
    sign_in users(:manager_marseille) # un seul service

    get interventions_url

    assert_response :success
    assert_select "select[name='service[]']", false,
                  'le filtre service doit être masqué pour un manager mono-service'
  end
end
