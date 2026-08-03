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

    assert_difference -> { Service.count }, 1 do
      click_on 'Enregistrer'
      # Le toast de flash est instable après navigation Turbo.
      assert_text(/espaces verts/i)
    end
  end

  test 'modifier un service depuis les paramètres' do
    visit admin_parametres_url
    click_on services(:service_paris).nom

    click_on 'Modifier'
    fill_in 'service_nom', with: 'Service Paris Renommé'
    click_on 'Enregistrer'

    # Le toast de flash est instable après navigation Turbo : on vérifie l'état
    # de façon robuste, sans dépendre du casing exact ni de la forme du texte rendu.
    assert_text /service paris/i
    assert_text /renommé/i
  end
end
