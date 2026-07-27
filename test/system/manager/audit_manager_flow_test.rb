# frozen_string_literal: true

require 'application_system_test_case'

class AuditManagerFlowTest < ApplicationSystemTestCase
  # Les system tests ne rollback pas entre eux (le navigateur a sa propre
  # connexion) : les audits créés par `audited` au fil des autres tests
  # persistent et rendraient ces filtres non déterministes (ex. un login d'agent
  # laisse un audit attribué à `bond`). On repart donc d'une table d'audits vide.
  #
  # Ensuite, au login, Devise (trackable) met à jour le manager → `audited` crée
  # UN unique audit (action `update`, type `User`, attribué au manager, dont
  # `audited_changes` contient les colonnes `sign_in_*`). C'est sur cet unique
  # audit que reposent toutes les assertions ci-dessous.
  setup do
    Audited::Audit.delete_all
    @manager = users(:hidalgo)
    login(@manager)
  end

  def go_to_audit_page
    # Fermer la notification de connexion
    fermer_notification

    # Le lien navbar n'existe plus en largeur mobile (dock simplifie par la refonte UX)
    visit admin_audits_path
    assert_selector 'h1', text: 'Activité' # attendre le chargement effectif de la page
  end

  # Recharge la page (état propre) sans tenter de refermer une notification déjà fermée.
  def recharger_audits
    visit admin_audits_path
    assert_selector 'h1', text: 'Activité'
  end

  # Les filtres Utilisateur/Type/Action sont dans un <details> replié par défaut
  # (refonte UX). Il faut l'ouvrir avant d'atteindre les slim-select qu'il contient.
  def ouvrir_criteres_avances
    find('summary', text: 'critères de filtrage').click
    sleep(0.3)
  end

  # Sélectionne une option dans un slim-select `multiple` puis referme le menu :
  # en mode multiple SlimSelect le laisse ouvert, et ses options intercepteraient
  # le clic d'activation du slim-select suivant. On clique à l'extérieur (le
  # titre) et on attend qu'aucune option ne soit plus visible avant de continuer.
  # La sélection robuste (recherche + clic) est dans le helper partagé `select_option`.
  #
  # Deux protections nées de flakiness observée (2026-07-15) :
  # - la sélection soumet le formulaire (onchange) → re-rendu Turbo qui
  #   ré-initialise les slim-selects : un menu peut transitoirement réapparaître
  #   ouvert après le clic extérieur → on referme en boucle courte ;
  # - sous forte charge, le clic d'option peut se perdre sans erreur (le select
  #   reste sur « Tous les … » et la page reste non filtrée) → on vérifie que le
  #   ss-main affiche bien la valeur choisie, sinon une seconde tentative.
  def choisir_filtre(id, value)
    2.times do |tentative|
      select_option(id, value)
      3.times do
        find('h1', text: 'Activité').click
        break if has_no_selector?('.ss-option', visible: true, wait: 1)
      end
      break if find(id, visible: false).sibling('div.ss-main').has_text?(value, wait: 2)

      flunk "La sélection « #{value} » dans #{id} n'a pas pris après 2 tentatives" if tentative == 1
    end
    assert_no_selector('.ss-option', visible: true, wait: 5)
  end

  test "Visiter l'index de l'audit trail" do
    go_to_audit_page
    assert_selector 'h1', text: 'Activité'
  end

  test "Vérifier que la liste n'est pas vide par défaut" do
    go_to_audit_page
    assert_selector 'table'
    assert_text @manager.email
  end

  test 'Rechercher dans les audits' do
    go_to_audit_page
    # Les noms de colonnes (sign_in_count, current_sign_in_at, …) figurent dans audited_changes.
    fill_in 'Rechercher', with: 'sign_in'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    assert_text @manager.email

    fill_in 'Rechercher', with: 'qzmoefij'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    assert_text 'Aucun résultat trouvé'
  end

  test 'Filter les audits par date' do
    go_to_audit_page
    # `<input type="date">` natif : on saisit une séquence de chiffres MMJJAAAA
    # (ordre des segments du widget), pas une chaîne à tirets DMY — sinon le
    # champ misparse et, en réécriture, produit une date invalide non soumise.
    fill_in 'Du', with: (Date.today - 14).strftime('%m%d%Y')
    fill_in 'Au', with: Date.today.strftime('%m%d%Y')
    # Attendre que le widget date ait bien assemblé la valeur avant de soumettre
    assert has_field?('Au', with: Date.today.strftime('%Y-%m-%d'), wait: 5)
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    assert_text @manager.email # l'audit du login (aujourd'hui) est dans la plage

    # Réécriture d'un champ date déjà rempli (le champ persiste hors du turbo-frame
    # rechargé, focus resté sur le segment année) : `fill_in` taperait dans l'année.
    # On revient au 1er segment (mois) via des flèches gauche avant de retaper MMJJAAAA.
    champ_au = find_field('Au')
    champ_au.send_keys(:arrow_left, :arrow_left, :arrow_left, (Date.today - 1).strftime('%m%d%Y'))
    assert has_field?('Au', with: (Date.today - 1).strftime('%Y-%m-%d'), wait: 5)
    champ_au.send_keys(:enter)
    assert_text 'Aucun résultat trouvé' # plage se terminant hier : exclut l'audit d'aujourd'hui
  end

  test 'Filter les audits par utilisateur' do
    agent = users(:bond)
    go_to_audit_page
    ouvrir_criteres_avances
    choisir_filtre('#user_id', @manager.nom)
    assert_text @manager.email

    recharger_audits
    ouvrir_criteres_avances
    choisir_filtre('#user_id', agent.nom)
    assert_text 'Aucun résultat trouvé' # l'agent n'a aucun audit
  end

  test 'Filter les audits par type' do
    go_to_audit_page
    ouvrir_criteres_avances
    choisir_filtre('#type', 'User')
    assert_text @manager.email
    # Un seul type d'audit existe (User) en l'état des fixtures : pas de cas négatif testable.
  end

  test 'Filter les audits par action' do
    go_to_audit_page
    ouvrir_criteres_avances
    choisir_filtre('#action_name', 'Modification') # action interne : update
    assert_text @manager.email

    recharger_audits
    ouvrir_criteres_avances
    choisir_filtre('#action_name', 'Suppression') # action interne : destroy
    assert_text 'Aucun résultat trouvé'
  end

  test 'Cumuler les filtres' do
    go_to_audit_page
    fill_in 'Du', with: (Date.today - 14).strftime('%m%d%Y')
    fill_in 'Au', with: Date.today.strftime('%m%d%Y')
    ouvrir_criteres_avances
    choisir_filtre('#user_id', @manager.nom)
    choisir_filtre('#type', 'User')
    choisir_filtre('#action_name', 'Modification')
    assert_text @manager.email # tous les filtres convergent vers l'unique audit de login

    fill_in 'Rechercher', with: 'qomzifj'
    page.driver.browser.switch_to.active_element.send_keys(:enter)
    assert_text 'Aucun résultat trouvé' # la recherche s'ajoute (AND) et exclut tout
  end
end
