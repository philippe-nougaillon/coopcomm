# frozen_string_literal: true

require 'test_helper'

class AdministrateurMessageriePolicyTest < ActionDispatch::IntegrationTest
  def setup
    administrateur = users(:administrateur_paris)

    interlocuteur = users(:bond)

    @policy = MessageriePolicy.new(administrateur, interlocuteur)
    @policy_annonces_service = MessageriePolicy.new(administrateur, services(:technique))
    @policy_annonces_service_non_rattaché = MessageriePolicy.new(administrateur, services(:secretariat))
    @policy_annonces_générales = MessageriePolicy.new(administrateur, organisations(:mairie_paris))
    @policy_annonces_autre_org = MessageriePolicy.new(administrateur, services(:service_marseille))
    @policy_annonces_générales_autre_org = MessageriePolicy.new(administrateur, organisations(:mairie_marseille))
  end

  test 'accès autorisé pour un administrateur sur une conversation avec un utilisateur' do
    assert @policy.index?
    assert @policy.conversation?
    assert @policy.send_message?
    assert @policy.search_contact?
    assert @policy.mark_as_read?
  end

  # ==================== TESTS CRITIQUES ====================
  # Un administrateur lit et publie dans tous les canaux d'annonces de son organisation,
  # services dont il n'est pas membre compris, et dans aucun d'une autre organisation.
  test 'accès autorisé pour un administrateur sur les annonces de son service (critique)' do
    assert @policy_annonces_service.annonces?
    assert @policy_annonces_service.send_annonce?
  end

  test "accès autorisé pour un administrateur sur les annonces d'un service de son organisation dont il n'est pas membre (critique)" do
    assert @policy_annonces_service_non_rattaché.annonces?
    assert @policy_annonces_service_non_rattaché.send_annonce?
  end

  test 'accès autorisé pour un administrateur sur les annonces générales de son organisation (critique)' do
    assert @policy_annonces_générales.annonces?
    assert @policy_annonces_générales.send_annonce?
  end

  test "accès interdit pour un administrateur sur les annonces d'une autre organisation (critique)" do
    refute @policy_annonces_autre_org.annonces?
    refute @policy_annonces_autre_org.send_annonce?
    refute @policy_annonces_générales_autre_org.annonces?
    refute @policy_annonces_générales_autre_org.send_annonce?
  end

  # ==================== /TESTS CRITIQUES ====================
end
