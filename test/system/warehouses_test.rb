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

    # État durable plutôt que le toast (volatil + couplé au wording) : create
    # redirige vers les paramètres, et le check en base ci-dessous prouve le succès.
    assert_current_path admin_parametres_path
    assert Warehouse.exists?(name: 'Atelier municipal')
  end

  test 'refuser un site sans localisation' do
    visit admin_parametres_url(tab: 'sites')
    click_sur_boutton_ajouter('warehouse')

    fill_in 'warehouse_name', with: 'Site sans adresse'
    click_on 'Enregistrer'

    # Create refusé → le formulaire est re-rendu en conservant la valeur saisie
    # (point de synchro indépendant du wording du message d'erreur). Un `assert_no_text`
    # sur le message de succès passerait trivialement si son libellé changeait.
    assert_field 'warehouse_name', with: 'Site sans adresse'
    assert_not Warehouse.exists?(name: 'Site sans adresse')
  end
end
