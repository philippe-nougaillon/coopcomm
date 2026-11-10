# frozen_string_literal: true

require 'test_helper'

class DocumentationDepuisLAccueilPublicTest < ActionDispatch::IntegrationTest
  test "En tant que visiteur non connecté, je veux consulter la documentation depuis la page d'accueil publique" do
    get welcome_path
    assert_dom 'a[href=?]', aide_path

    get aide_path
    assert_response :success
  end
end
