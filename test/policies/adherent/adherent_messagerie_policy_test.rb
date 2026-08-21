# frozen_string_literal: true

require 'test_helper'

class AdherentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(adherent, interlocuteur)
  end

  test 'accès autorisé pour un adhérent sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end
end
