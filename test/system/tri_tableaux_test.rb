# frozen_string_literal: true

require 'application_system_test_case'

# Les tests contrôleur exercent chaque colonne déclarée ; ici on prouve que
# l'en-tête est bien un lien cliquable et que le clic réordonne la page.
class TriTableauxTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'cliquer une entête de la liste des utilisateurs réordonne le tableau' do
    visit users_url

    noms = -> { all('#users tbody tr td:nth-child(2)').map { |cellule| cellule.text.strip } }
    croissant = noms.call

    cliquer_lien 'Email'

    assert_current_path(/column=users.email/)
    assert_selector 'th[aria-sort=ascending]', text: /Email/i

    cliquer_lien 'Nom'

    assert_selector 'th[aria-sort=ascending]', text: /Nom/i
    assert_equal croissant, noms.call

    cliquer_lien 'Nom'

    assert_selector 'th[aria-sort=descending]', text: /Nom/i
    assert_not_equal croissant.first, noms.call.first
  end

  test 'trier ne renvoie pas en haut de la page' do
    page.driver.browser.manage.window.resize_to(1280, 600)
    visit users_url
    page.execute_script('window.scrollTo(0, 400)')

    cliquer_lien 'Email'

    assert_selector 'th[aria-sort=ascending]', text: /Email/i
    assert_operator page.evaluate_script('window.scrollY'), :>, 0
  end

  test 'un bouton de workflow reste utilisable dans un tableau encadré' do
    intervention = interventions(:intervention_autre_agent)
    visit interventions_url(vue: 'compact', search: intervention.description)

    cliquer_bouton 'Valider'

    assert_text 'Intervention validée'
    assert_equal 'validé', intervention.reload.workflow_state
  end

  test 'le tri survit au filtrage' do
    visit users_url

    cliquer_lien 'Email'

    assert_selector 'th[aria-sort=ascending]', text: /Email/i

    fill_in 'search', with: 'o'
    find('#search').send_keys(:enter)

    assert_selector 'th[aria-sort=ascending]', text: /Email/i
  end

  test 'cliquer une entête de la vue compacte des interventions réordonne le tableau' do
    visit interventions_url(vue: 'compact')

    descriptions = -> { all('#intervenant tbody tr td:nth-child(3)').map { |cellule| cellule.text.strip } }

    cliquer_lien 'Description'

    assert_selector 'th[aria-sort=ascending]', text: /Description/i
    croissant = descriptions.call

    cliquer_lien 'Description'

    assert_selector 'th[aria-sort=descending]', text: /Description/i
    assert_equal croissant.reverse, descriptions.call
  end

  test 'chaque onglet des paramètres garde son propre tri' do
    login(users(:administrateur_paris))
    visit admin_parametres_url(tab: 'prestations')

    cliquer_lien 'Libellé'

    assert_selector 'th[aria-sort=ascending]', text: /Libellé/i
    assert_current_path(/tab=prestations/)
  end
end
