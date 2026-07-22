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
    assert_text @commande.intitulé.capitalize
  end

  test 'updating a Commande' do
    visit commande_url(@commande)
     # click_on 'Modifier'

    # « Intitulé » existe aussi sur les lignes de prestation → on cible le champ de la commande par son id.
    fill_in 'Intitulé', with: 'Devis nettoyage révisé'
    click_on 'Enregistrer'

    # On vérifie l'état métier (le toast de flash est instable après navigation Turbo).
    assert_text 'Devis Nettoyage Révisé'
    assert_equal 'Devis nettoyage révisé', @commande.reload.intitulé
  end

  test 'destroying a Commande' do
    visit commandes_url

    within('tr', text: @commande.intitulé) do
      find("button[title='Supprimer']").click
    end
    click_on 'Oui, supprimer'

    assert_no_selector 'tr', text: @commande.intitulé
    assert @commande.reload.discarded?
  end
end
