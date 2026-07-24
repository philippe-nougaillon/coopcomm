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
    select_option('#tool_icon_name', 'Tracteur')
  

    # Destination inconnue d'avance (nouvel enregistrement) : on attend que le
    # formulaire ait été quitté avant d'asserter le contenu de la page d'arrivée.
    soumettre 'enregistrer_tool'

    assert_text 'MX57SH3V'
    assert Tool.exists?(name: 'Tondeuse à gazon', marque: 'Marina Systems')
  end

  test 'Supprimer un outil' do
    outil = tools(:outil_paris)
    visit tool_url(outil)

    # La refonte UX a remplacé le confirm() natif par une modale <dialog> :
    # le bouton « Supprimer » l'ouvre, « Oui, supprimer » confirme (même flux
    # que commandes/factures, cf. 2026-07-22).
    cliquer_element(find("button[title='Supprimer']"))
    cliquer_bouton('Oui, supprimer')

    # État métier plutôt que le toast : celui-ci s'auto-détruit au bout de 5 s,
    # l'asserter est un pile ou face (doctrine 2026-06-12 §7).
    assert_current_path tools_path
    assert_no_text outil.name
    assert_not Tool.exists?(outil.id)
  end

  test 'Ne pas pouvoir supprimer un outil avec une intervention' do
    visit tool_url(tools(:tondeuse))

    # La refonte UX masque le bouton de suppression au lieu de le désactiver
    assert_no_selector '#supprimer_outil'
  end
end
