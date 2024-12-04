require "application_system_test_case"

class ManagerFlowTest < ApplicationSystemTestCase

  setup do
    login(@manager)
  end
  
  test "visiting the index" do
    visit interventions_url
    assert_selector "h1", text: "Interventions"
  end

  test "Se déconnecter" do
    sleep(5)
    logout_button = find("[title=\"Fermer la session de #{@manager.email} (#{@manager.rôle})\"]")
    page.accept_confirm do
      logout_button.click
    end
    assert_text "Déconnecté(e) avec succès."
    visit interventions_url
    assert_text "Vous devez vous connecter ou vous enregistrer pour continuer."
  end

  # test "créer intervention" do
  #   click_on "Ajouter une Intervention"
  #   fill_in "Description", with: "Tailler les arbres"
  #   # fill_in "Mots clés", with: "tailler"
  #   # js_select 'tailler', from: 'Mots clés'
  #   # find("select[id='intervention_adherent_id']").select_option('Weil Ariel')
  #   # js_select "Weil Ariel", from: "Adhérent"
  #   select_from_slim_select("Weil Ariel", from: "Adhérent")
  #   # js_select "Team Électricité", from: "Équipe"
  #   # js_select "Bond James", from: "Agent 1"
  #   fill_in 'Début', with: DateTime.current.strftime("%m%d%Y\t%I%M%P")
  #   fill_in 'Fin', with: (DateTime.current + 8.hours).strftime("%m%d%Y\t%I%M%P")
  #   page.select "1.0", from: "Temps de pause (h)"
  #   fill_in "Commentaires", with: "Ceci est un commentaire !"
  #   click_on "Créer un(e) Intervention"
  #   assert_text "Intervention créée avec succès."
  # end

  test "modifier intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    click_on "Modifier"
    fill_in "Description", with: "Installer la fibre"
    click_on "Modifier ce(tte) Intervention"
    assert_no_text "Modifier intervention"
    assert_text "Installer la fibre"
  end

  test "supprimer intervention" do
    intervention = interventions(:tonte_locaux)
    click_on intervention.description
    sleep(1)
    delete_button = find("[data-testid=\"Supprimer l'intervention\"]")
    page.accept_confirm do
      delete_button.click
    end
    assert_text "Intervention supprimée avec succès."
  end

  test "terminer une intervention" do
    find("a:not([disabled])", text: "Terminer", match: :first).click
    assert_text "Intervention terminée"
  end

  test "valider une intervention" do
    find("a:not([disabled])", text: "Valider", match: :first).click
    assert_text "Intervention validée"
  end

  test "refuser une intervention" do
    find("a:not([disabled])", text: "Refuser", match: :first).click
    assert_text "Intervention refusée"
  end

  test "créer un utilisateur" do
    click_on "Liste des utilisateurs"
    sleep(1)
    click_on "Ajouter un Utilisateur"
    sleep(1)
    fill_in "Nom", with: "Thomas"
    fill_in "Prénom", with: "Didier"
    fill_in "Email", with: "thomas.didier@gmail.commmm"
    fill_in "Mot de passe", with: "c39abcba457c93bcc0a7"
    fill_in "Confirmation du mot de passe", with: "c39abcba457c93bcc0a7"
    page.select "agent", from: "Rôle"
  end

  test "modifier un utilisateur" do
    user = users(:bond)
    click_on "Liste des utilisateurs"
    sleep(1)
    click_on user.nom_prénom
    sleep(1)
    click_on "Modifier"
    fill_in "Nom", with: "Thomas"
    fill_in "Prénom", with: "Didier"
    fill_in "Email", with: "thomas.didier@gmail.commmm"
    page.select "manager", from: "Rôle"
    click_on "Modifier ce(tte) Utilisateur"
    sleep(1)
    assert_text "Utilisateur modifié avec succès."
    assert_text "THOMAS Didier"
    assert_text "thomas.didier@gmail.commmm"
    assert_text "Manager"
  end

  test "supprimer un utilisateur" do
    user = users(:bond)
    click_on "Liste des utilisateurs"
    sleep(1)
    click_on user.nom_prénom
    delete_button = find("[data-testid=\"Supprimer l'utilisateur\"]")
    page.accept_confirm do
      delete_button.click
    end
    assert_text "Utilisateur supprimé avec succès."
    click_on "Liste des utilisateurs"
    assert_no_text user.nom_prénom
  end

  test "ne pas avoir accès aux informations d'une autre organisation" do
    user = users(:manager_marseille)
    intervention = interventions(:nettoyage_port)
    assert_no_text intervention.description
    visit users_url
    assert_no_text user.nom_prénom
    visit user_url(user.slug)
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_selector "h1", text: "Interventions"
  end

  # test "le temps total est correctement calculé" do
  
  # end

  # test "les filtres fonctionnent dans interventions/users/maillogs" do

  # end

  # test "export XLS" do

  # end

end