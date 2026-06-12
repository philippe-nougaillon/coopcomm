# frozen_string_literal: true

require 'application_system_test_case'

class ServicesTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    login(@admin)
  end

  test 'créer un service depuis les paramètres' do
    visit admin_parametres_url
    click_sur_boutton_ajouter('service')

    assert_selector 'h1', text: 'Nouveau service'
    fill_in 'service_nom', with: 'Espaces Verts'
    click_on 'Enregistrer'

    assert_text 'Service créé avec succès'
  end

  test 'modifier un service depuis les paramètres' do
    visit admin_parametres_url
    click_on services(:service_paris).nom

    click_on 'Modifier'
    fill_in 'service_nom', with: 'Service Paris Renommé'
    click_on 'Enregistrer'

    # Le toast de flash est instable après navigation Turbo : on vérifie l'état
    assert_text 'Service paris renommé'
  end
end
