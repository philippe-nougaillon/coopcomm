# frozen_string_literal: true

require 'test_helper'

class OngletOrganisationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:administrateur_paris)
  end

  test "En tant qu'administrateur, je veux ouvrir l'onglet Organisation depuis les paramètres" do
    get admin_parametres_path
    assert_dom 'a[href=?]', organisation_path, text: /Organisation/

    get organisation_path
    assert_response :success
  end

  test "En tant qu'administrateur, je veux revenir aux autres onglets des paramètres depuis l'onglet Organisation" do
    get organisation_path
    assert_dom 'a[href=?]', admin_parametres_path(tab: 'services'), text: /Services/
    assert_dom 'a[href=?]', admin_parametres_path(tab: 'sites'), text: /Sites/
    assert_dom 'a[href=?]', admin_parametres_path(tab: 'prestations'), text: /Prestations/

    get admin_parametres_path(tab: 'prestations')
    assert_response :success
  end

  test "En tant qu'administrateur, je veux modifier mon organisation depuis l'onglet Organisation puis y revenir" do
    get organisation_path
    assert_dom 'a[href=?]', edit_organisation_path, text: /Modifier/

    get edit_organisation_path
    assert_dom 'a[href=?]', organisation_path, text: /Retour aux paramètres/
  end

  test "En tant qu'administrateur, je veux retrouver le nouveau nom de mon organisation sur sa page après l'avoir modifié" do
    patch organisation_path, params: { organisation: { nom: 'Mairie de Lutèce' } }
    follow_redirect!

    assert_dom '#organisation', text: /Mairie de Lutèce/
    assert_dom '#notification', text: /Organisation modifiée avec succès/
  end
end
