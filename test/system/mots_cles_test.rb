# frozen_string_literal: true

require 'application_system_test_case'

# Saisie des mots clés au navigateur. Le champ est un slim-select, et lui seul décide
# si un mot clé inédit peut être créé : `data-addable` n'est posé que sur le champ des
# managers. Rien de tout cela n'est visible d'un test de contrôleur.
class MotsClesTest < ApplicationSystemTestCase
  setup do
    @intervention = interventions(:tonte_locaux)
  end

  test 'un manager crée un mot clé inédit depuis le formulaire' do
    login(users(:hidalgo))
    visit edit_intervention_path(@intervention)

    ajouter_mot_cle('#intervention_tags_manager', 'plantation')
    soumettre 'enregistrer_intervention'

    assert_equal ['plantation'], @intervention.reload.tag_list
  end

  test 'un manager choisit un mot clé déjà utilisé ailleurs' do
    interventions(:nouvelle_intervention).update!(tag_list: 'élagage')
    login(users(:hidalgo))
    visit edit_intervention_path(@intervention)

    select_option('#intervention_tags_manager', 'élagage')
    fermer_menus_slim_select
    soumettre 'enregistrer_intervention'

    assert_equal ['élagage'], @intervention.reload.tag_list
  end

  test 'un manager retire un mot clé' do
    @intervention.update!(tag_list: 'urgence, plomberie')
    login(users(:hidalgo))
    visit edit_intervention_path(@intervention)

    retirer_mot_cle('#intervention_tags_manager', 'plomberie')
    soumettre 'enregistrer_intervention'

    assert_equal ['urgence'], @intervention.reload.tag_list
  end

  test 'le champ de l’agent ne propose pas de créer un mot clé inédit' do
    login(users(:bond))
    visit edit_intervention_path(@intervention)

    activate_dropdown_slimSelect('#intervention_tags_intervenant')
    find('.ss-search input', visible: true).set('mot-clé-inédit')

    assert_no_selector '.ss-addable'
    assert_no_text 'pour ajouter'
  end

  test 'un agent choisit un mot clé déjà utilisé ailleurs' do
    interventions(:nouvelle_intervention).update!(tag_list: 'élagage')
    login(users(:bond))
    visit edit_intervention_path(@intervention)

    select_option('#intervention_tags_intervenant', 'élagage')
    fermer_menus_slim_select
    soumettre 'enregistrer_intervention'

    assert_equal ['élagage'], @intervention.reload.tag_list
  end

  private

  # Le « + » de slim-select : il n'apparaît dans la zone de recherche que si le champ
  # porte `data-addable`, et il crée l'option à la volée.
  def ajouter_mot_cle(id, valeur)
    dans_le_menu(id, valeur) { find('.ss-addable', visible: true).click }
  end

  # Cliquer une option déjà sélectionnée la désélectionne.
  def retirer_mot_cle(id, valeur)
    dans_le_menu(id, valeur) do
      within('.ss-list') { find('div.ss-option.ss-selected', text: valeur, match: :first).click }
    end
  end

  # Même précaution que `select_option` : la liste se reconstruit à chaque frappe de la
  # recherche, l'élément visé peut donc devenir obsolète entre le `find` et le clic.
  def dans_le_menu(id, valeur)
    tentatives = 0
    begin
      activate_dropdown_slimSelect(id)
      find('.ss-search input', visible: true).set(valeur)
      yield
    rescue *RACE_SLIM_SELECT
      tentatives += 1
      raise if tentatives >= 3

      fermer_menus_slim_select
      sleep 0.4
      retry
    end
    fermer_menus_slim_select
  end
end
