# frozen_string_literal: true

require 'application_system_test_case'

class UserManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  test 'créer un utilisateur' do
    visit users_url
    click_sur_boutton_ajouter('utilisateur')
    sleep(1)
    fill_in 'Nom', with: 'Thomas'
    fill_in 'Prénom', with: 'Didier'
    fill_in 'Adresse email', with: 'thomas.didier@gmail.commmm'
    # (mot de passe généré + invitation ; rôle réservé aux administrateurs)
    select_option('#user_service_ids', 'Technique')

    click_on 'enregistrer_utilisateur'

    sleep(1)
    créé = User.find_by(email: 'thomas.didier@gmail.commmm')
    assert créé, "l'utilisateur n'a pas été créé"
    assert créé.agent?, 'un manager ne crée que des agents'
  end

  test 'modifier un utilisateur' do
    user = users(:bond)
    visit users_url
    click_on user.nom_prénom
    sleep(1)
    click_on 'Modifier', match: :first
    fill_in 'Nom', with: 'Thomas'
    fill_in 'Prénom', with: 'Didier'
    fill_in 'Adresse email', with: 'thomas.didier@gmail.commmm'
    # (le changement de rôle est désormais réservé aux administrateurs)
    click_on 'enregistrer_utilisateur'
    sleep(1)
    assert_text 'Utilisateur modifié avec succès.'
    assert_text 'THOMAS Didier'
    assert_text 'thomas.didier@gmail.commmm'
  end

  test 'supprimer un utilisateur' do
    user = users(:bond)
    visit users_url
    click_on user.nom_prénom
    # La suppression passe désormais par une modale de confirmation HTML
    click_on 'Supprimer'
    click_on 'Oui, supprimer'
    sleep(1)
    visit users_url
    assert_no_text user.nom_prénom
  end

  # test "les filtres fonctionnent dans la liste des utilisateurs" do
  # end
end
