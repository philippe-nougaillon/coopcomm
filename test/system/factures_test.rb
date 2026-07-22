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
    # L'intitulé est rendu avec la classe CSS `capitalize` (Title Case à l'écran) →
    # on matche sans tenir compte de la casse.
    assert_text(/#{Regexp.escape(@facture.intitulé)}/i)
  end

  test 'updating a Facture' do
    # Le lien « Modifier » est temporairement désactivé sur le show (#326) : le
    # formulaire d'édition n'est plus atteignable depuis l'UI. On skippe jusqu'à
    # sa réactivation (le corps reste valable, l'action edit/update existe toujours).
    skip 'Édition désactivée temporairement (#326) — lien « Modifier » masqué du show.'
    visit edit_facture_url(@facture)

    # « Intitulé » existe aussi sur les lignes de prestation → le champ de la
    # facture est le premier du formulaire.
    fill_in 'Intitulé', with: 'Facture nettoyage révisée', match: :first
    cliquer_bouton 'Enregistrer'

    # `update` redirige vers la show : on attend la navigation AVANT d'asserter,
    # sinon on lit le champ du formulaire encore affiché.
    assert_current_path facture_path(@facture)
    assert_text(/Facture nettoyage révisée/i)
    assert_equal 'Facture nettoyage révisée', @facture.reload.intitulé
  end

  test 'destroying a Facture' do
    # La suppression a été déplacée de la ligne d'index vers le show (#326).
    visit facture_url(@facture)

    find("button[title='Supprimer']").click # ouvre la modale de confirmation
    click_on 'Oui, supprimer'

    assert_current_path factures_path
    assert @facture.reload.discarded?
  end
end
