require "application_system_test_case"

class UserManagerFlowTest < ApplicationSystemTestCase

  setup do
    @manager = users(:hidalgo)
    login(@manager)
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
    click_on "enregistrer_utilisateur"
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

  # test "les filtres fonctionnent dans la liste des utilisateurs" do
  # end

end