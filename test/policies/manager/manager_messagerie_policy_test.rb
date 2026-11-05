# frozen_string_literal: true

require 'test_helper'

class ManagerMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    manager = users(:hidalgo)

    interlocuteur = users(:martin_technique_paris)

    @policy = MessageriePolicy.new(manager, interlocuteur)
    @policy_annonces_service = MessageriePolicy.new(manager, services(:technique))
    @policy_annonces_générales = MessageriePolicy.new(manager, organisations(:mairie_paris))
    @policy_annonces_autre_service = MessageriePolicy.new(manager, services(:secretariat))
    @policy_annonces_autre_org = MessageriePolicy.new(manager, services(:service_marseille))
    @policy_annonces_générales_autre_org = MessageriePolicy.new(manager, organisations(:mairie_marseille))
  end

  test 'accès autorisé pour un manager sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end

  # ==================== TESTS CRITIQUES ====================
  # Un manager publie dans les annonces des services qu'il gère, lit les annonces générales sans
  # y publier, et ne lit rien hors de ses services ni hors de son organisation.
  test 'accès autorisé pour un manager sur les annonces de son service (critique)' do
    assert @policy_annonces_service.annonces?
    assert @policy_annonces_service.send_annonce?
  end

  test 'accès autorisé pour un manager sur les annonces générales de son organisation (critique)' do
    assert @policy_annonces_générales.annonces?
  end

  test 'accès interdit pour un manager sur la publication des annonces générales (critique)' do
    refute @policy_annonces_générales.send_annonce?
  end

  test "accès interdit pour un manager sur les annonces d'un service qu'il ne gère pas (critique)" do
    refute @policy_annonces_autre_service.annonces?
    refute @policy_annonces_autre_service.send_annonce?
  end

  test "accès interdit pour un manager sur les annonces d'une autre organisation (critique)" do
    refute @policy_annonces_autre_org.annonces?
    refute @policy_annonces_autre_org.send_annonce?
    refute @policy_annonces_générales_autre_org.annonces?
    refute @policy_annonces_générales_autre_org.send_annonce?
  end

  # ==================== /TESTS CRITIQUES ====================
end
