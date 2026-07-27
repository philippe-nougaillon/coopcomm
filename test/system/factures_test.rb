# frozen_string_literal: true

require 'application_system_test_case'

# Réécrit depuis le scaffold généré (qui ne se connectait pas et cliquait des
# libellés anglais inexistants). Pas de test de création : `new`/`create` sont
# volontairement désactivés dans le contrôleur — une facture naît d'une commande
# (CreateFactureFromCommande), jamais d'un formulaire « New facture ».
class FacturesTest < ApplicationSystemTestCase
  setup do
    # hidalgo gère le service « informatique », auquel facture_paris est rattachée.
    login(users(:hidalgo))
    @facture = factures(:facture_paris) # état « créé » → modifiable
  end

  test 'visiting the index' do
    visit factures_url

    assert_selector 'h1', text: 'Factures'
    assert_text @facture.ref
  end

  test 'showing a facture' do
    visit facture_url(@facture)

    assert_text @facture.ref
    assert_text css_capitalize(@facture.intitulé)
  end

  test 'updating a Facture' do
    visit facture_url(@facture)
    click_on 'Modifier'

    # « Intitulé » existe aussi sur les lignes de prestation → on cible le champ de la facture par son id.
    fill_in 'facture_intitulé', with: 'Facture nettoyage révisée'
    cliquer_bouton 'Enregistrer'

    # `update` redirige vers la show : on attend la navigation AVANT d'asserter,
    # sinon on lit le champ du formulaire encore affiché.
    assert_current_path facture_path(@facture)
    assert_text css_capitalize('Facture nettoyage révisée')
    assert_equal 'Facture nettoyage révisée', @facture.reload.intitulé
  end

  test 'destroying a Facture' do
    visit facture_url(@facture)

    find("[data-testid='supprimer_facture']").click # ouvre la modale de confirmation
    click_on 'Oui, supprimer'

    assert_current_path factures_path
    assert_no_selector 'tr', text: css_capitalize(@facture.intitulé)
    assert @facture.reload.discarded?
  end
end
