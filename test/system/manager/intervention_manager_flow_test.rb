# frozen_string_literal: true

require 'application_system_test_case'

class InterventionManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'Voir la liste des interventions en se connectant' do
    # Depuis #291 la connexion arrive sur la page d'accueil, pas sur la liste
    assert_selector 'h1', text: 'Bonjour'
    visit interventions_url
    assert_selector 'h1', text: 'Interventions'
  end

  test 'Créer intervention' do
    visit interventions_url
    click_sur_boutton_ajouter('intervention')

    fill_in 'Description', with: 'Tailler les arbres'

    # Sélectionner le tag
    activate_dropdown_slimSelect('#intervention_tags_manager')
    page.driver.browser.switch_to.active_element.send_keys('Coupure électricité', :enter, 'Réparation', :enter)

    # Sélectionner l'adhérent
    select_option('#intervention_adherent_id', 'Weil Ariel')

    # Le select Service (requis) se peuple après le choix de l'adhérent
    select_option('#intervention_service_id', 'Informatique')

    # Sélectionner l'agent
    select_option('#intervention_agent_ids', 'Bond James')

    # Créneau réalisé dans le passé (une date future est refusée par validation)
    fill_in 'Début', with: (Date.today - 1).strftime('%m%d%Y')
    select '08', from: 'intervention_début_hour'
    select '00', from: 'intervention_début_minute'
    fill_in 'Fin', with: (Date.today - 1).strftime('%m%d%Y')
    select '16', from: 'intervention_fin_hour'
    select '00', from: 'intervention_fin_minute'

    # Le label « Pause (h) » n'a plus d'attribut `for` → on cible le select par son id.
    page.select '1,0', from: 'intervention_temps_de_pause'
    fill_in 'Commentaires', with: 'Ceci est un commentaire !'
    click_on 'enregistrer_intervention'

    # La création aboutit (POST 303) mais la navigation Turbo qui suit est
    # capricieuse (GET négocié turbo-stream) : on vérifie en base puis on visite.
    créée = nil
    10.times do
      créée = Intervention.find_by(description: 'Tailler les arbres')
      break if créée

      sleep 0.3
    end
    assert créée, "l'intervention n'a pas été créée"
    visit intervention_url(créée)
    assert_text 'Tailler les arbres'
  end

  # Anti-régression : la recherche SlimSelect (réglage `showSearch`, actif par défaut)
  # avait été désactivée par `showSearch: false` (commit 1f3dc709), empêchant de filtrer
  # en tapant. On la teste sur le slim-select le plus important du projet : l'assignation
  # des agents (#intervention_agent_ids, partial _form_for_agents) — un select groupé et
  # multiple.
  test 'le slim-select des agents propose une recherche qui filtre les options' do
    visit new_intervention_url

    activate_dropdown_slimSelect('#intervention_agent_ids')

    # Garde anti-faux-positif : les deux agents sont bien présents AVANT de filtrer
    # (sinon l'assertion de disparition passerait sans que le filtrage ne marche).
    within('.ss-list') do
      assert_selector '.ss-option', text: 'Bond James'
      assert_selector '.ss-option', text: 'Martin Michel'
    end

    # La barre de recherche doit exister (cœur de la régression) et filtrer la liste.
    find('.ss-search input').set('Bond')

    within('.ss-list') do
      assert_selector '.ss-option', text: 'Bond James'
      assert_no_selector '.ss-option', text: 'Martin Michel'
    end
  end

  # Anti-régression : un select `required` masqué par SlimSelect doit rester FOCUSABLE,
  # sinon la validation HTML5 ne peut pas l'atteindre au submit (« An invalid form
  # control ... is not focusable ») et l'erreur passe inaperçue pour l'utilisateur.
  # La régression venait d'un `visibility: hidden` ajouté au CSS (commit 1f3dc709) ;
  # `opacity: 0` masque déjà le champ tout en le laissant focusable.
  test 'un slim-select requis reste focusable pour la validation HTML5' do
    visit new_intervention_url

    # #intervention_adherent_id est `required` et rendu invisible par slim-select.
    style = page.evaluate_script(<<~JS)
      (() => {
        const el = document.getElementById('intervention_adherent_id');
        if (!el) return null;
        const cs = getComputedStyle(el);
        document.body.focus();
        el.focus();
        return { visibility: cs.visibility, display: cs.display, focused: document.activeElement === el };
      })()
    JS

    assert style, '#intervention_adherent_id introuvable sur le formulaire'
    assert_not_equal 'hidden', style['visibility'], 'visibility:hidden rend le champ non-focusable'
    assert_not_equal 'none', style['display'], 'display:none rend le champ non-focusable'
    assert style['focused'], 'le select requis masqué par slim-select doit rester focusable'
  end

  test 'Modifier intervention' do
    visit interventions_url
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on 'Modifier'
    fill_in 'Description', with: 'Installer la fibre'
    # La refonte UX vide le select Service à l'édition (required) : il faut re-choisir
    select_option('#intervention_service_id', 'Informatique')
    click_on 'enregistrer_intervention'
    assert_no_text 'Modifier intervention'
    assert_text 'Installer la fibre'
  end

  test 'Supprimer intervention' do
    # tonte_locaux a des mouvements rattachés (bouton désactivé) : on prend
    # une intervention supprimable
    visit intervention_url(interventions(:nouvelle_intervention))
    delete_button = find("[data-testid=\"Supprimer l'intervention\"]")
    page.accept_confirm do
      delete_button.click
    end
    # On vérifie l'état métier (le toast de flash est instable après un DELETE Turbo)
    assert_no_text 'Ramasser les feuilles'
    assert_not Intervention.exists?(interventions(:nouvelle_intervention).id)
  end

  test 'Terminer une intervention' do
    visit intervention_url(interventions(:nouvelle_intervention))
    click_button 'Terminer'
    assert_text 'Intervention terminée'
  end

  test 'Valider une intervention' do
    visit intervention_url(interventions(:intervention_terminée))
    click_button 'Valider'
    assert_text 'Intervention validée'
  end

  test 'Refuser une intervention' do
    visit intervention_url(interventions(:intervention_terminée))
    click_button 'Refuser'
    assert_text 'Intervention refusée'
  end

  # Anti-régression (bug visuel) : sur l'index en vue « normale », chaque carte
  # d'intervention est un composant DaisyUI `collapse`. Son <input type=checkbox>
  # (z-index 1) recouvre tout l'en-tête pour capter le clic d'ouverture/fermeture
  # et INTERCEPTE donc les clics sur les boutons d'action. Ceux-ci ne passent
  # au-dessus que s'ils sont positionnés (`relative z-10`) — un `z-10` seul est
  # inopérant sur un élément statique. Sans le correctif, Selenium lève
  # ElementClickInterceptedError sur ce clic : ce test échoue si la régression revient.
  # (Les tests Terminer/Valider/Refuser ci-dessus passent par la page `show`, qui
  # n'est PAS un collapse, et ne couvrent donc pas ce cas.)
  test "les boutons d'action d'une carte d'intervention sont cliquables sur l'index (collapse)" do
    intervention = interventions(:nouvelle_intervention)
    visit interventions_url(vue: 'normal')

    # Garde anti-faux-positif : la carte et son bouton sont bien rendus.
    assert_selector "#intervention_#{intervention.id}", text: 'Terminer'

    within "#intervention_#{intervention.id}" do
      click_on 'Terminer'
    end

    # Point de synchronisation : `button_to turbo:false` recharge la page (le flash
    # est fiable en rechargement complet, contrairement à une navigation Turbo).
    assert_text 'Intervention terminée'
    # L'assertion qui compte reste l'état métier en base.
    assert_equal 'terminé', intervention.reload.workflow_state
  end

  # !!! Tests sur les filtres obsolètes !!!

  # TODO VU: Rendre dynamique les assert_text
  # On s'en occupera avec l'US #332
  # test "Rechercher dans les interventions" do
  #   # Recherche sur les descriptions
  #   fill_in "Rechercher", with: "asser les feui"
  #   page.driver.browser.switch_to.active_element.send_keys(:enter)
  #   # assert_text "Affichage de 1 élément"
  #
  #   # Recherche sur les commentaires
  #   fill_in "Rechercher", with: "le bord"
  #   page.driver.browser.switch_to.active_element.send_keys(:enter)
  #   # assert_text "Affichage de 1 élément"
  #
  #   # Mauvaise recherche
  #   fill_in "Rechercher", with: "qzmeoifqze"
  #   page.driver.browser.switch_to.active_element.send_keys(:enter)
  #   # assert_text "Aucun élément trouvé"
  # end
  #
  # test "Filter les interventions par date" do
  #   fill_in "Du", with: Date.today.strftime("%d-%m-%Y")
  #   fill_in "Au", with: (Date.today + 30).strftime("%d-%m-%Y")
  #   sleep(1)
  #   page.driver.browser.switch_to.active_element.send_keys(:enter)
  #   # assert_text "Affichage de 1 élément"
  #
  #   fill_in "Au", with: (Date.today + 7).strftime("%d-%m-%Y")
  #   sleep(1)
  #   page.driver.browser.switch_to.active_element.send_keys(:enter)
  #   # assert_text "Aucun élément trouvé"
  # end

  # Il faut mettre un placeholder dans le slimselect
  # test "Filter les interventions par adhérent" do
  #   adhérent = users(:weil)
  #   adhérent_sans_intervention = users(:adhérent_sans_intervention)
  #   select adhérent.nom_prénom, from: "Adhérent"
  #   assert_text "Affichage de 1 élément"
  #   select adhérent_sans_intervention.nom_prénom, from: "Adhérent"
  #   assert_text "Aucun élément trouvé"
  # end

  # test "Filter les interventions par statut" do
  #   select 'Nouveau', from: "Statut"
  #   # assert_text "Affichage de 2 éléments"
  #   select 'Validé', from: "Statut"
  #   # assert_text "Affichage de 1 élément"
  # end

  # # Fonctionnalité enlevée
  # test "Filter les interventions à venir / toutes" do
  #   assert_text "Affichage de 4 éléments"
  #   find("[data-testid=\"filtres_toutes\"]").click
  #   assert_text "Affichage de 5 éléments"
  # end

  # TODO VU: à faire
  # On s'en occupera avec l'US #332
  # test "Filter les interventions sur les tags" do
  #   assert_text "Affichage de 4 éléments"
  #   assert_text "Affichage de 1 élément"
  # end

  # test "Le temps total d'une intervention est correctement calculé" do
  # end

  # test "Export XLS des interventions" do
  # end
end
