# frozen_string_literal: true

require 'application_system_test_case'

class MouvementsTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'visiter la liste des mouvements' do
    visit mouvements_url

    assert_selector 'h1', text: 'Mouvements'
    assert_text 'Tondeuse' # mouvement de la fixture mouvement_tondeuse
  end

  test 'déclarer une panne via le formulaire' do
    visit new_mouvement_url

    select_option '#mouvement_tool_id', 'Tondeuse'
    select 'Panne', from: 'mouvement_état'
    page.execute_script("document.getElementById('mouvement_date').value = '#{Date.tomorrow}T10:00'")
    fill_in 'mouvement_commentaires', with: 'Courroie cassée'
    click_on 'Enregistrer'

    assert_text 'Mouvement créé avec succès'
    panne = Mouvement.order(:created_at).last
    assert panne.panne?
    assert_equal tools(:tondeuse), panne.tool
  end

  test 'ne pas pouvoir déclarer deux pannes actives sur le même outil' do
    tools(:tondeuse).mouvements.create!(état: :panne, date: Time.current, user: @manager)

    visit new_mouvement_url
    select_option '#mouvement_tool_id', 'Tondeuse'
    select 'Panne', from: 'mouvement_état'
    page.execute_script("document.getElementById('mouvement_date').value = '#{Date.tomorrow}T10:00'")
    click_on 'Enregistrer'

    assert_text 'déjà', wait: 5 # message de cohérence du model (panne déjà active)
  end
end
