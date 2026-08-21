# frozen_string_literal: true

require 'test_helper'

class AdministrateurMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(administrateur, interlocuteur)
  end

  test 'accès autorisé pour un administrateur sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end
end
