# frozen_string_literal: true

require 'test_helper'

class AgentMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    agent = users(:martin_technique_paris)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(agent, interlocuteur)
    @policy_annonces_service = MessageriePolicy.new(agent, services(:technique))
    @policy_annonces_générales = MessageriePolicy.new(agent, organisations(:mairie_paris))
    @policy_annonces_autre_service = MessageriePolicy.new(agent, services(:informatique))
    @policy_annonces_autre_org = MessageriePolicy.new(agent, services(:service_marseille))
    @policy_annonces_générales_autre_org = MessageriePolicy.new(agent, organisations(:mairie_marseille))
  end

  test 'accès autorisé pour un agent sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end

  # ==================== TESTS CRITIQUES ====================
  # Un agent lit les annonces de son service et les annonces générales, n'en publie aucune,
  # et ne lit rien hors de son service ni hors de son organisation.
  test 'accès autorisé pour un agent sur les annonces de son service (critique)' do
    assert @policy_annonces_service.annonces?
  end

  test 'accès interdit pour un agent sur la publication dans les annonces de son service (critique)' do
    refute @policy_annonces_service.send_annonce?
  end

  test 'accès autorisé pour un agent sur les annonces générales de son organisation (critique)' do
    assert @policy_annonces_générales.annonces?
  end

  test 'accès interdit pour un agent sur la publication des annonces générales (critique)' do
    refute @policy_annonces_générales.send_annonce?
  end

  test "accès interdit pour un agent sur les annonces d'un service qui n'est pas le sien (critique)" do
    refute @policy_annonces_autre_service.annonces?
    refute @policy_annonces_autre_service.send_annonce?
  end

  test "accès interdit pour un agent sur les annonces d'une autre organisation (critique)" do
    refute @policy_annonces_autre_org.annonces?
    refute @policy_annonces_autre_org.send_annonce?
    refute @policy_annonces_générales_autre_org.annonces?
    refute @policy_annonces_générales_autre_org.send_annonce?
  end

  # ==================== /TESTS CRITIQUES ====================
end
