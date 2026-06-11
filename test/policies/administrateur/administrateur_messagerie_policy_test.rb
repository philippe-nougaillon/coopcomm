# frozen_string_literal: true

require 'test_helper'

class AdministrateurMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    interlocutor_user = users(:bond)

    @policy = MessageriePolicy.new(administrateur, interlocutor_user)
  end

  # Messagerie
  test 'accès autorisé pour un administrateur sur la page index de messagerie' do
    assert @policy.index?
  end

  # Send message
  test 'accès autorisé pour un administrateur sur la page send_message de messagerie' do
    assert @policy.send_message?
  end

  # Search contact
  test 'accès autorisé pour un administrateur sur la page search_contact de messagerie' do
    assert @policy.search_contact?
  end

  # Mark as read
  test 'accès autorisé pour un adminisdtrateur sur la page mark_as_read de messagerie' do
    assert @policy.mark_as_read?
  end
end
