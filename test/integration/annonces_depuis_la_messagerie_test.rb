# frozen_string_literal: true

require 'test_helper'

class AnnoncesDepuisLaMessagerieTest < ActionDispatch::IntegrationTest
  test "En tant qu'administrateur, je veux ouvrir les annonces d'un service depuis l'accueil de la messagerie" do
    sign_in users(:administrateur_paris)
    annonces_technique = messagerie_annonces_path(service_slug: services(:technique).slug)

    get messagerie_path
    assert_dom 'a[href=?]', annonces_technique, text: /Réunion d'équipe vendredi/

    get annonces_technique
    assert_response :success
  end
end
