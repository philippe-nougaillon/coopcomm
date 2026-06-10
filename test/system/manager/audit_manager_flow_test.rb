# frozen_string_literal: true

require 'application_system_test_case'

class AuditManagerFlowTest < ApplicationSystemTestCase
  # TODO: Rendre dynamique les assert_text

  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  def go_to_audit_page
    # Fermer la notification de connexion
    find("[data-testid='close_notification']").click

    # Cliquer sur le bouton 'audit trail' de la navbar
    find("[data-testid='audit_trail']").click
    sleep(1)
  end

  test "Visiter l'index de l'audit trail" do
    go_to_audit_page
    assert_selector 'h1', text: 'Activité'
  end

  test "Vérifier que la liste n'est pas vide par défaut" do
    go_to_audit_page
    assert_selector 'table'
    # assert_text "Affichage de 1 élément"
  end

  test 'Rechercher dans les audits' do
    go_to_audit_page
    fill_in 'Rechercher', with: '127.0.0.1'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    # assert_text "Affichage de 1 élément"
    fill_in 'Rechercher', with: 'qzmoefij'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    # assert_text "Aucun élément trouvé"
  end

  test 'Filter les audits par date' do
    go_to_audit_page
    fill_in 'Du', with: (Date.today - 14).strftime('%d-%m-%Y')
    fill_in 'Au', with: Date.today.strftime('%d-%m-%Y')
    sleep(1)
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    # assert_text "Affichage de 1 élément"

    fill_in 'Au', with: (Date.today - 1).strftime('%d-%m-%Y')
    sleep(1)
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    # assert_text "Aucun élément trouvé"
  end

  test 'Filter les audits par utilisateur' do
    agent = users(:bond)
    go_to_audit_page
    select @manager.nom, from: 'Utilisateur'
    # assert_text "Affichage de 1 élément"
    select agent.nom, from: 'Utilisateur'
    # assert_text "Aucun élément trouvé"
  end

  test 'Filter les audits par type' do
    go_to_audit_page
    select 'User', from: 'Type'
    # assert_text "Affichage de 1 élément"

    # pas possible parce qu'il y a pour l'instant qu'un seul audit et que la liste est basé sur les audits créés par l'organisation
    # select "Intervention", from: "Type"
    # assert_text "Aucun élément trouvé"
  end

  test 'Filter les audits par action' do
    go_to_audit_page
    select 'update', from: 'Action'
    # assert_text "Affichage de 1 élément"
    select 'destroy', from: 'Action'
    # assert_text "Aucun élément trouvé"
  end

  test 'Cumuler les filtres' do
    go_to_audit_page
    fill_in 'Rechercher', with: '127.0.0.1'
    fill_in 'Du', with: (Date.today - 14).strftime('%d-%m-%Y')
    fill_in 'Au', with: Date.today.strftime('%d-%m-%Y')
    select @manager.nom, from: 'Utilisateur'
    select 'User', from: 'Type'
    select 'update', from: 'Action'
    # assert_text "Affichage de 1 élément"

    fill_in 'Rechercher', with: 'qomzifj'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    # assert_text "Aucun élément trouvé"
  end
end
