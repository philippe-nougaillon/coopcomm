# frozen_string_literal: true

require 'application_system_test_case'

class InterventionsIndexTest < ApplicationSystemTestCase
  test 'le filtre service est masqué pour un utilisateur mono-service' do
    login(users(:manager_marseille))

    visit interventions_url

    assert_no_selector "select[name='service[]']", visible: :all
  end

  test 'le filtre service reste visible pour un manager multi-services' do
    login(users(:hidalgo))

    visit interventions_url

    assert_selector "select[name='service[]']", visible: :all
  end

  test 'le filtre service reste visible pour un administrateur' do
    login(users(:administrateur_paris))

    visit interventions_url

    assert_selector "select[name='service[]']", visible: :all
  end

  test 'le formulaire soumet toujours un champ caché service[] pour distinguer vidé de non soumis' do
    login(users(:administrateur_paris))

    visit interventions_url

    assert_selector "input[type=hidden][name='service[]']", visible: :all
  end

  test 'au premier affichage aucun service n’est présélectionné' do
    login(users(:administrateur_paris))

    visit interventions_url

    assert_no_selector "select[name='service[]'] option[selected]", visible: :all
  end

  test 'un paramètre forgé n’est pas réinjecté dans les liens de la page' do
    login(users(:administrateur_paris))

    visit interventions_url(equipe: ['mairie'])

    assert_selector 'h1'
    assert_no_match(/equipe/, page.html)
  end
end
