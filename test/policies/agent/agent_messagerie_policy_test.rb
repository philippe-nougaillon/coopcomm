# frozen_string_literal: true

require 'test_helper'

class AgentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(agent, interlocuteur)
  end

  test 'accès autorisé pour un agent sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end
end
