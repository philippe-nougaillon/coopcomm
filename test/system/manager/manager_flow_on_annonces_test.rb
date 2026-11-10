# frozen_string_literal: true

require 'application_system_test_case'

class ManagerFlowOnAnnoncesTest < ApplicationSystemTestCase
  setup do
    login(users(:hidalgo))
  end

  test "En tant que manager, je veux publier une annonce dans mon service depuis la messagerie" do
    visit messagerie_path
    ouvrir_contacts
    cliquer_lien 'Technique'

    fill_in 'message', with: 'Réunion lundi 8 h'
    cliquer_element(element_testid('envoyer_message'))

    assert_field 'message', with: ''
    annonce = Message.annonce.find_by(message: 'Réunion lundi 8 h')
    assert_equal [users(:hidalgo).id, services(:technique).id], [annonce.from_id, annonce.to_id]
  end

  test "En tant que manager, je veux retrouver les annonces repliées en revenant sur la messagerie" do
    visit messagerie_path
    ouvrir_contacts
    cliquer_element(find('summary', text: 'ANNONCES'))
    assert_no_link 'Technique'

    visit messagerie_path
    ouvrir_contacts

    assert_link 'Weil Ariel'
    assert_no_link 'Technique'
  end
end
