# frozen_string_literal: true

require 'application_system_test_case'

class MouvementsTest < ApplicationSystemTestCase
  setup do
    @mouvement = mouvements(:one)
  end

  test 'visiting the index' do
    visit mouvements_url
    assert_selector 'h1', text: 'Mouvements'
  end

  test 'should create mouvement' do
    visit mouvements_url
    click_on 'New mouvement'

    fill_in 'Slug', with: @mouvement.slug
    fill_in 'Tool', with: @mouvement.tool_id
    fill_in 'état', with: @mouvement.état
    click_on 'Create Mouvement'

    assert_text 'Mouvement was successfully created'
    click_on 'Back'
  end

  test 'should update Mouvement' do
    visit mouvement_url(@mouvement)
    click_on 'Edit this mouvement', match: :first

    fill_in 'Slug', with: @mouvement.slug
    fill_in 'Tool', with: @mouvement.tool_id
    fill_in 'état', with: @mouvement.état
    click_on 'Update Mouvement'

    assert_text 'Mouvement was successfully updated'
    click_on 'Back'
  end

  test 'should destroy Mouvement' do
    visit mouvement_url(@mouvement)
    accept_confirm { click_on 'Destroy this mouvement', match: :first }

    assert_text 'Mouvement was successfully destroyed'
  end
end
