# frozen_string_literal: true

require 'test_helper'
require_relative '../support/compte_aibbo'

class NiveauDeReflexionAibboTest < ActionDispatch::IntegrationTest
  include CompteAibbo

  setup do
    sign_in users(:administrateur_paris)
  end

  test "En tant qu'administrateur, je veux retrouver le niveau de réflexion choisi pour AÏBBO en rouvrant la conversation" do
    post messagerie_send_message_url, params: { message: 'Combien d’interventions ?', to_user_slug: users(:AIBBO).slug, niveau: 'approfondi' }

    get messagerie_conversation_url(users(:AIBBO).slug)

    assert_dom 'select[name=niveau] option[selected]', text: 'Approfondi'
  end
end
