# frozen_string_literal: true

require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:carte_grise)
    sign_in users(:hidalgo)
  end

  test 'doit être validé' do
    post valider_document_url(@document)
    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Document accepté', flash[:notice]
  end

  test 'doit être refusé' do
    post refuser_document_url(@document)
    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Document refusé', flash[:notice]
  end

  test 'ne peut pas être validé si il est déjà validé' do
    @document.valider!
    post valider_document_url(@document)

    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Le document est déjà validé', flash[:alert]
  end

  test 'ne peut pas être refusé si il est déjà refusé' do
    @document.refuser!
    post refuser_document_url(@document)

    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Le document est déjà refusé', flash[:alert]
  end

  test 'ne peut pas être validé si il est refusé' do
    @document.refuser!
    post valider_document_url(@document)

    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Le document ne peut pas être validé', flash[:alert]
  end

  test 'ne peut pas être refusé si il est validé' do
    @document.valider!
    post refuser_document_url(@document)

    assert_redirected_to tool_url(@document.tool)
    assert_equal 'Le document ne peut pas être refusé', flash[:alert]
  end
end
