# frozen_string_literal: true

require 'application_system_test_case'

class CotationsTest < ApplicationSystemTestCase
  setup do
    @admin = users(:administrateur_paris)
    @adherent = users(:weil) # adhérent de mairie_paris
    login(@admin)
  end

  # Parcours bout-en-bout : slim_select (service + prestation) et ligne imbriquée.
  # On vérifie en base que le JS a bien produit les bons paramètres et que le
  # serveur a calculé le total à partir du tarif de la prestation.
  test "création d'une cotation avec une ligne via le formulaire" do
    visit new_cotation_path(adherent_id: @adherent.slug) # adhérent figé

    fill_in 'Intitulé', with: 'Devis système', match: :first
    select_option '#cotation_service_id', 'Informatique'
    select_option '#cotation_cotation_lignes_attributes_0_prestation_id', 'Nettoyage de bureaux'
    fill_in 'Qté', with: 3, match: :first

    click_on 'Enregistrer'
    assert_text 'Cotation créée'

    cotation = Cotation.order(:created_at).last
    assert_equal 'Devis système', cotation.intitulé
    assert_equal 1, cotation.cotation_lignes.count
    assert_equal 76.5, cotation.total_ht.to_f # 25,50 € × 3
    assert_equal 'créé', cotation.workflow_state
  end

  # Comportement client pur (controller Stimulus nested-form), non atteignable
  # par les tests de contrôleur.
  test 'le formulaire ajoute et retire des lignes de prestation' do
    visit new_cotation_path(adherent_id: @adherent.slug)

    assert_selector '.nested-form-wrapper', count: 1
    click_on 'Ajouter une prestation'
    assert_selector '.nested-form-wrapper', count: 2

    within all('.nested-form-wrapper').last do
      find("button[data-action='nested-form#remove']").click
    end
    assert_selector '.nested-form-wrapper', count: 1
  end
end
