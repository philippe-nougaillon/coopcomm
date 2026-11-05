# frozen_string_literal: true

require 'test_helper'

class AdherentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent = users(:weil)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(adherent, interlocuteur)
    @policy_annonces_service = MessageriePolicy.new(adherent, services(:technique))
    @policy_annonces_générales = MessageriePolicy.new(adherent, organisations(:mairie_paris))
  end

  test 'accès autorisé pour un adhérent sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end

  # ==================== TESTS CRITIQUES ====================
  # Les annonces sont réservées à l'équipe : un adhérent n'en lit ni n'en publie, même dans ses services.
  test 'accès interdit pour un adhérent sur les annonces de son service (critique)' do
    refute @policy_annonces_service.annonces?
    refute @policy_annonces_service.send_annonce?
  end

  test 'accès interdit pour un adhérent sur les annonces générales de son organisation (critique)' do
    refute @policy_annonces_générales.annonces?
    refute @policy_annonces_générales.send_annonce?
  end

  # ==================== /TESTS CRITIQUES ====================
end
