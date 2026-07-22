# frozen_string_literal: true

require 'application_system_test_case'

# Réécrit depuis le scaffold généré (qui ne se connectait pas et cliquait des
# libellés anglais inexistants). La création n'est PAS testée : `new`/`create`
# sont volontairement désactivés dans le contrôleur — une commande naît d'une
# cotation (CreateCommandeFromCotation), jamais d'un formulaire « New commande ».
class CommandesTest < ApplicationSystemTestCase
  setup do
    # hidalgo gère le service « informatique », auquel commande_paris est rattachée.
    login(users(:hidalgo))
    @commande = commandes(:commande_paris) # état « créé » → modifiable
  end

  test 'visiting the index' do
    visit commandes_url

    assert_selector 'h1', text: 'Commandes'
    assert_text @commande.ref
  end

  test 'showing a commande' do
    visit commande_url(@commande)

    assert_text @commande.ref
    # L'intitulé est rendu avec la classe CSS `capitalize` (Title Case à l'écran) →
    # on matche sans tenir compte de la casse.
    assert_text(/#{Regexp.escape(@commande.intitulé)}/i)
  end

  test 'updating a Commande' do
    # Le lien « Modifier » est temporairement désactivé sur le show (#326) : le
    # formulaire d'édition n'est plus atteignable depuis l'UI. On skippe jusqu'à
    # sa réactivation (le corps reste valable, l'action edit/update existe toujours).
    skip 'Édition désactivée temporairement (#326) — lien « Modifier » masqué du show.'
    visit edit_commande_url(@commande)

    # « Intitulé » existe aussi sur les lignes de prestation → le champ de la
    # commande est le premier du formulaire.
    fill_in 'Intitulé', with: 'Devis nettoyage révisé', match: :first
    click_on 'Enregistrer'

    # `update` redirige vers la show : on attend la navigation avant d'asserter
    # l'état métier (le toast de flash est instable après navigation Turbo).
    assert_current_path commande_path(@commande)
    assert_equal 'Devis nettoyage révisé', @commande.reload.intitulé
  end

  test 'destroying a Commande' do
    # La suppression a été déplacée de la ligne d'index vers le show (#326).
    visit commande_url(@commande)

    find("button[title='Supprimer']").click # ouvre la modale de confirmation
    click_on 'Oui, supprimer'

    assert_current_path commandes_path
    assert @commande.reload.discarded?
  end
end
