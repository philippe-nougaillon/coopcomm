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

  # Parcours « outil imposé » : arrivée via new_mouvement_path(tool_id:) (ex. lien "Panne"
  # depuis la fiche d'un outil). Le champ outil doit être caché, pas un select.
  test 'outil imposé : le champ est caché et la panne est créée sur cet outil' do
    visit new_mouvement_url(tool_id: tools(:tondeuse).id)

    assert_no_selector "select[name='mouvement[tool_id]']", visible: :all
    assert_selector "input[type=hidden][name='mouvement[tool_id]'][value='#{tools(:tondeuse).id}']", visible: :all

    select 'Panne', from: 'mouvement_état'
    page.execute_script("document.getElementById('mouvement_date').value = '#{Date.tomorrow}T10:00'")
    fill_in 'mouvement_commentaires', with: 'Lame émoussée'
    click_on 'Enregistrer'

    assert_text 'Mouvement créé avec succès'
    panne = Mouvement.order(:created_at).last
    assert panne.panne?
    assert_equal tools(:tondeuse), panne.tool
  end

  # Crux du correctif : après une erreur de validation, l'outil imposé (transporté dans
  # l'URL du POST) reste caché — on ne réaffiche pas le select.
  test 'outil imposé : le champ reste caché après une erreur de validation' do
    tools(:tondeuse).mouvements.create!(état: :panne, date: Time.current, user: @manager)

    visit new_mouvement_url(tool_id: tools(:tondeuse).id)
    select 'Panne', from: 'mouvement_état'
    page.execute_script("document.getElementById('mouvement_date').value = '#{Date.tomorrow}T10:00'")
    click_on 'Enregistrer'

    assert_text 'déjà', wait: 5 # l'erreur de cohérence s'affiche
    assert_no_selector "select[name='mouvement[tool_id]']", visible: :all # toujours pas de select
    assert_selector "input[type=hidden][name='mouvement[tool_id]']", visible: :all # champ resté caché
  end
end
