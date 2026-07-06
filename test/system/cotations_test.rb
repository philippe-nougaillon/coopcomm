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

  # --- Signature (parcours adhérent) ---
  # cotation_secretariat : adhérent weil, état « envoyé », audit `create` par
  # administrateur_paris (créateur notifiable → chemin nominal avec redirection).

  # Parcours bout-en-bout : l'adhérent trace une signature sur le pad puis signe.
  # Le workflow transite vers « signé », la signature/date/IP sont persistées et
  # l'on est redirigé vers la cotation. Non atteignable par un test de contrôleur
  # (le pad de signature est du JS pur : SignaturePad + toDataURL).
  test 'un adhérent signe une cotation en traçant sa signature' do
    login(@adherent)
    cotation = cotations(:cotation_secretariat) # envoyé, à weil

    visit signer_cotation_path(cotation)
    assert_text 'Cotation à signer'

    draw_signature
    assert_no_selector '#save[disabled]' # le tracé active le bouton

    accept_confirm { find('#save').click }

    # État métier durable (les toasts de flash sont instables après navigation).
    assert_current_path cotation_path(cotation)
    cotation.reload
    assert_equal 'signé', cotation.workflow_state
    assert cotation.signature.present?
    assert_not_nil cotation.signee_le
    assert cotation.ip.present?
  end

  # Câblage JS pur ajouté au pad (`refreshSaveButton`) : le bouton « Signer » est
  # désactivé tant que le cadre est vide, activé dès un trait, et « Effacer » le
  # re-désactive. Invisible aux tests de contrôleur.
  test 'le bouton Signer est désactivé tant que le cadre de signature est vide' do
    login(@adherent)

    visit signer_cotation_path(cotations(:cotation_secretariat))
    assert_selector '#save[disabled]' # état initial : vide → désactivé

    draw_signature
    assert_no_selector '#save[disabled]' # un trait → activé

    find('#clear').click
    assert_selector '#save[disabled]' # ré-effacé → re-désactivé
  end

  private

  # Trace un petit trait sur le canvas SignaturePad via l'API d'actions Selenium.
  # Le `pointerup` de fin déclenche `refreshSaveButton` (activation du bouton) et
  # remplit le pad, si bien que `toDataURL` produit une vraie signature.
  def draw_signature
    canvas = find('#signature-pad')
    page.driver.browser.action
        .move_to(canvas.native)
        .click_and_hold
        .move_by(25, 30)
        .move_by(30, -20)
        .move_by(-25, 25)
        .release
        .perform
  end
end
