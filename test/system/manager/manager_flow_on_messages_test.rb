# frozen_string_literal: true

require 'application_system_test_case'
require_relative '../../support/compte_aibbo'

class ManagerFlowOnMessagesTest < ApplicationSystemTestCase
  include CompteAibbo
  include ActiveJob::TestHelper

  setup do
    login(users(:hidalgo))
  end

  test "En tant que manager, je veux trouver un contact par la recherche quand les messages privés sont repliés" do
    visit messagerie_path
    ouvrir_contacts
    cliquer_element(find('summary', text: 'MESSAGE PRIVÉ'))
    assert_no_link 'Weil Ariel'

    fill_in 'query', with: 'Weil'

    assert_link 'Weil Ariel'
  end

  test "En tant que manager, je veux déplier une longue réponse d'AÏBBO pour la lire jusqu'au bout" do
    Message.create!(from_user: users(:AIBBO), to_user: users(:hidalgo),
                    message: "#{"- une intervention du service Technique\n" * 40}\nFin de la réponse")
    visit messagerie_path
    ouvrir_contacts
    cliquer_lien 'AÏBBO'
    assert_no_text 'Fin de la réponse'

    cliquer_bouton 'Voir plus'

    assert_text 'Fin de la réponse'
    assert_no_button 'Voir plus'
  end

  test "En tant que manager, je veux choisir le niveau de réflexion d'AÏBBO avant de lui poser ma question" do
    visit messagerie_path
    ouvrir_contacts
    cliquer_lien 'AÏBBO'
    select 'Approfondi', from: 'niveau'
    fill_in 'message', with: 'Combien d’interventions terminées ?'

    cliquer_element(element_testid('envoyer_message'))

    assert_field 'message', with: ''
    assert_enqueued_with(job: RepondreAibboJob, args: [users(:hidalgo), Message.last, 'approfondi'])
  end
end
