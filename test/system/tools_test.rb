# frozen_string_literal: true

require 'application_system_test_case'

class ToolsTest < ApplicationSystemTestCase
  setup do
    login(users(:hidalgo))
  end

  test 'Voir la liste des outils' do
    visit tools_url
    assert_selector 'h1', text: 'Réservation de matériel'
  end

  test 'Créer un outil' do
    visit tools_url

    click_sur_boutton_ajouter('outil')

    fill_in 'Nom', with: 'Tondeuse à gazon'
    fill_in 'Description', with: 'Tondeuse professionnelle acier inox Marina Systems MX57SH3V moteur Honda GXV160'
    fill_in 'Modèle', with: 'MX57SH3V'
    fill_in 'Marque', with: 'Marina Systems'
    within('#tool_icon_name') do
      find('option', text: 'Tracteur').click
    end

    click_on 'enregistrer_tool'

    # On vérifie l'état (le toast de flash est instable après navigation Turbo)
    assert_text 'MX57SH3V'
    assert Tool.exists?(name: 'Tondeuse à gazon', marque: 'Marina Systems')
  end

  test 'Supprimer un outil' do
    visit tool_url(tools(:outil_paris))

    accept_confirm do
      click_on 'supprimer_outil'
    end

    assert_text 'Outil supprimé avec succès.'
  end

  test 'Ne pas pouvoir supprimer un outil avec une intervention' do
    visit tool_url(tools(:tondeuse))

    # La refonte UX masque le bouton de suppression au lieu de le désactiver
    assert_no_selector '#supprimer_outil'
  end
end
