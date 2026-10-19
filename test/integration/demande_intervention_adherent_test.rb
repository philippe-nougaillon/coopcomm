# frozen_string_literal: true

require 'test_helper'

class DemandeInterventionAdherentTest < ActionDispatch::IntegrationTest
  setup do
    @adherent = users(:weil)
    @intervention = interventions(:intervention_repete)

    sign_in @adherent
  end

  test "En tant qu'adhérent, je veux ouvrir le formulaire de demande d'intervention depuis les accès rapides" do
    get home_path

    assert_response :success
    assert_dom "a[href=?]", new_intervention_path, text: /Créer une Intervention/

    get new_intervention_path

    assert_response :success
    assert_dom "form[action=?]", interventions_path
  end

  test "En tant qu'adhérent, je veux modifier la description de mon intervention depuis son bouton Modifier" do
    get intervention_path(@intervention)

    assert_response :success
    assert_dom "a[href=?]", edit_intervention_path(@intervention)

    get edit_intervention_path(@intervention)

    assert_response :success

    patch intervention_path(@intervention), params: {
      intervention: { description: 'Élaguer les tilleuls de la place' }
    }

    assert_redirected_to intervention_url(@intervention)
    assert_equal 'Élaguer les tilleuls de la place', @intervention.reload.description

    follow_redirect!
    assert_dom '#intervention_' + @intervention.id.to_s, text: /Élaguer les tilleuls de la place/
  end
end
