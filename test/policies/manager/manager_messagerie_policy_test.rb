# frozen_string_literal: true

require 'test_helper'

class ManagerMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    interlocuteur = users(:martin_technique_paris)

    @policy = MessageriePolicy.new(manager, interlocuteur)
  end

  test 'accès autorisé pour un manager sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end
end
