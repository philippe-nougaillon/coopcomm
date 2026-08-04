# frozen_string_literal: true

require 'application_system_test_case'

class UserFormTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    @agent = users(:martin_technique_paris)
    login(@admin)
  end

  # Le refus doit laisser un formulaire pleinement utilisable : sans widget
  # slim-select reconstruit, la CSS de `select.slim-select[required]` laisse un
  # champ invisible et l'utilisateur ne peut plus corriger sa saisie.
  test 'après un refus, le champ Service reste visible et permet de corriger' do
    visit edit_user_path(@agent)
    select_option('#user_service_ids', 'Informatique')
    fermer_menus_slim_select
    cliquer_bouton 'enregistrer_utilisateur'

    assert_text "ne doit comporter qu'un seul service"

    widget_service = find('#user_service_ids', visible: false).sibling('div.ss-main')
    assert widget_service.visible?, 'le champ Service a disparu après le refus'
    assert_equal %w[Informatique Technique], widget_service.text.split("\n").sort

    widget_role = find('#user_rôle', visible: false).sibling('div.ss-main')
    assert widget_role.visible?, 'le champ Rôle a disparu après le refus'

    select_option('#user_service_ids', 'Informatique')
    fermer_menus_slim_select
    cliquer_bouton 'enregistrer_utilisateur'

    assert_current_path user_path(@agent)
    assert_equal ['Technique'], @agent.reload.services.pluck(:nom)
  end
end
