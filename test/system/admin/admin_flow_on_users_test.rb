# frozen_string_literal: true

require 'application_system_test_case'

class AdminFlowOnUsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    login(@admin)
    fermer_notification
  end

  test "En tant qu'administrateur, je veux créer un adhérent depuis la page d'accueil (critique)" do
    visit home_path

    ouvrir_dropdown 'Gestion'
    cliquer_lien 'Utilisateurs'
    assert_current_path users_path

    click_sur_boutton_ajouter('utilisateur')
    assert_selector 'h1', text: 'Nouvel utilisateur'

    select_option('#user_rôle', 'adhérent')
    fermer_menus_slim_select
    fill_in 'Nom', with: 'Weiss'
    fill_in 'Adresse email', with: 'nathalie.weiss@ville-paris.fr'
    poser_localisation('12 rue de Rivoli, Paris', 48.8566, 2.3522)
    select_option('#user_service_ids', 'Technique')
    fermer_menus_slim_select

    cliquer_bouton 'Enregistrer'

    assert_notification 'Utilisateur créé avec succès.'

    adherent_créé = User.find_by(email: 'nathalie.weiss@ville-paris.fr')
    assert adherent_créé, "l'adhérent n'a pas été créé"
    assert_current_path user_path(adherent_créé)
    assert adherent_créé.adhérent?, 'le rôle adhérent n’a pas été enregistré'
    assert_equal ['Technique'], adherent_créé.services.pluck(:nom)

    assert_selector 'tr', text: 'Invitation envoyée'
  end

  private

  # L'autocomplétion Google Places remplit l'adresse ET les coordonnées, toutes
  # trois exigées d'un adhérent ; une adresse tapée au clavier sans suggestion
  # choisie laisse les coordonnées vides et le widget la retire du formulaire.
  def poser_localisation(adresse, latitude, longitude)
    page.execute_script(<<~JS, adresse.to_s, latitude.to_s, longitude.to_s)
      document.querySelector('[data-places-target="address"]').value = arguments[0]
      document.querySelector('[data-places-target="latitude"]').value = arguments[1]
      document.querySelector('[data-places-target="longitude"]').value = arguments[2]
    JS
  end
end
