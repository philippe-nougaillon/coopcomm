# frozen_string_literal: true

require 'application_system_test_case'

# ⚠ Tests commentés (décision client) : le workflow de validation des
# documents d'outil a été débranché par la refonte UX.
class DocumentsTest < ApplicationSystemTestCase
  # setup do
  #   @tool = tools(:tondeuse)
  #   @document = documents(:carte_grise)
  #
  #   login(users(:hidalgo))
  # end

  # test 'should create document' do
  #   visit edit_tool_url(@tool)
  #
  #   attach_file('tool_documents_attributes_0_fichier', 'test/fixtures/files/carte_grise.jpg')
  #
  #   attach_file('tool_documents_attributes_1_fichier', 'test/fixtures/files/certificat_assurance.jpg')
  #
  #   select('validé', from: 'tool_documents_attributes_1_workflow_state')
  #
  #   click_on 'enregistrer_tool'
  #   assert_text 'Outil modifié avec succès'
  # end

  # test 'should validate document' do
  #   visit tool_url(@tool)
  #
  #   assert_button 'Valider', disabled: false, match: :first
  #   assert_button 'Refuser', disabled: false, match: :first
  #
  #   click_on 'Valider', match: :first
  #
  #   assert_selector 'button.btn[disabled]', text: 'Valider', match: :first
  #   assert_selector 'button.btn[disabled]', text: 'Refuser', match: :first
  # end

  # test 'should refuse document' do
  #   visit tool_url(@tool)
  #
  #   assert_button 'Valider', disabled: false, match: :first
  #   assert_button 'Refuser', disabled: false, match: :first
  #
  #   click_on 'Refuser', match: :first
  #
  #   assert_selector 'button.btn[disabled]', text: 'Valider', match: :first
  #   assert_selector 'button.btn[disabled]', text: 'Refuser', match: :first
  # end
end
