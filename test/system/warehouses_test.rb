# frozen_string_literal: true

require 'application_system_test_case'

class WarehousesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    login(@admin)
  end

  test 'créer un site depuis les paramètres' do
    visit admin_parametres_url(tab: 'sites')
    click_sur_boutton_ajouter('warehouse')

    assert_selector 'h1', text: 'Nouveau site'
    fill_in 'warehouse_name', with: 'Atelier municipal'
    fill_in 'warehouse_address', with: '1 rue de la Mairie'
    # Les coordonnées sont normalement posées par l'autocomplétion Google Places
    page.execute_script("document.querySelector('[data-places-target=\"latitude\"]').value = '48.89'")
    page.execute_script("document.querySelector('[data-places-target=\"longitude\"]').value = '6.05'")
    click_on 'Enregistrer'

    assert_text 'Site créé avec succès'
    assert Warehouse.exists?(name: 'Atelier municipal')
  end

  test 'refuser un site sans localisation' do
    visit admin_parametres_url(tab: 'sites')
    click_sur_boutton_ajouter('warehouse')

    fill_in 'warehouse_name', with: 'Site sans adresse'
    click_on 'Enregistrer'

    assert_no_text 'Site créé avec succès'
    assert_not Warehouse.exists?(name: 'Site sans adresse')
  end
end
