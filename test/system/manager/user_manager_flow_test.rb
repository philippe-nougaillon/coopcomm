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
    fill_in 'Nom', with: 'Thomas'
    fill_in 'Prénom', with: 'Didier'
    fill_in 'Adresse email', with: 'thomas.didier@gmail.commmm'
    # (mot de passe généré + invitation ; rôle réservé aux administrateurs)
    select_option('#user_service_ids', 'Technique')

    # Destination inconnue d'avance : on attend que le formulaire ait été quitté
    # avant de lire la page d'arrivée puis la base.
    soumettre 'enregistrer_utilisateur'

    assert_text 'THOMAS Didier'
    créé = User.find_by(email: 'thomas.didier@gmail.commmm')
    assert créé, "l'utilisateur n'a pas été créé"
    assert créé.agent?, 'un manager ne crée que des agents'
  end

  test 'modifier un utilisateur' do
    user = users(:bond)
    visit users_url
    click_on user.nom_prénom
    click_on 'Modifier', match: :first
    fill_in 'Nom', with: 'Thomas'
    fill_in 'Prénom', with: 'Didier'
    fill_in 'Adresse email', with: 'thomas.didier@gmail.commmm'
    # (le changement de rôle est désormais réservé aux administrateurs) `cliquer_bouton`
    # recentre le bouton : en largeur mobile le dock fixe du bas recouvrait le submit et…
    cliquer_bouton 'enregistrer_utilisateur'

    # `update` redirige vers la show : on attend la navigation, puis l'état métier
    # (le toast s'auto-détruit au bout de 5 s — l'asserter est un pile ou face).
    assert_current_path user_path(user)
    assert_text 'THOMAS Didier'
    assert_text 'thomas.didier@gmail.commmm'
  end

  test 'supprimer un utilisateur' do
    user = users(:bond)
    visit users_url
    click_on user.nom_prénom
    # La suppression est devenue une désactivation (soft-delete) via une modale HTML
    click_on "Désactiver l'utilisateur"
    click_on 'Oui, désactiver'
    # La désactivation redirige vers l'index (users#destroy → users_url) : le nom est
    # affiché sur le show courant.
    assert_no_text user.nom_prénom
  end

  # test "les filtres fonctionnent dans la liste des utilisateurs" do
  # end
end
