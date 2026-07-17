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

    click_on 'enregistrer_utilisateur'

    # Synchronisation : attendre le rendu de la page show (redirect 303) avant
    # de lire la base — click_on rend la main dès le clic, avant la fin du POST.
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
    # (le changement de rôle est désormais réservé aux administrateurs)
    click_on 'enregistrer_utilisateur'
    assert_text 'Utilisateur modifié avec succès.'
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
    # La désactivation redirige vers l'index (users#destroy → users_url) : le nom
    # est affiché sur le show courant, donc cette assertion attend de fait la fin
    # du soft-delete ET l'arrivée sur l'index qui ne liste plus l'utilisateur.
    assert_no_text user.nom_prénom
  end

  # test "les filtres fonctionnent dans la liste des utilisateurs" do
  # end
end
