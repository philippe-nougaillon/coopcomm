# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'
require_relative '../support/faux_ovh'

class InstanceIaTest < ActiveSupport::TestCase
  include FauxModele
  include FauxOvh

  setup do
    brancher_faux_modele
    brancher_faux_ovh('SHELVED_OFFLOADED')
  end

  teardown do
    debrancher_faux_ovh
    debrancher_faux_modele
  end

  test 'l’instance se pilote quand les cinq variables OVH sont renseignées' do
    assert InstanceIa.pilotable?
  end

  test 'l’instance ne se pilote pas dès qu’une variable OVH manque' do
    ENV['OVH_CONSUMER_KEY'] = nil

    assert_not InstanceIa.pilotable?
  end

  test 'l’état de l’instance est celui que rend l’API OVH' do
    assert_equal 'SHELVED_OFFLOADED', InstanceIa.etat
  end

  test 'l’état affiché sur la page d’analyse est celui que rend l’API OVH' do
    assert_equal 'SHELVED_OFFLOADED', InstanceIa.etat_affiche
  end

  test 'aucun état n’est affiché quand l’instance ne se pilote pas' do
    ENV['OVH_CONSUMER_KEY'] = nil

    assert_nil InstanceIa.etat_affiche
    assert_not_requested(:get, INSTANCE_OVH)
  end

  test 'aucun état n’est affiché quand l’API OVH ne répond pas, sans erreur pour la page (critique)' do
    stub_request(:get, INSTANCE_OVH).to_timeout

    assert_nil InstanceIa.etat_affiche
  end

  test 'le réveil demande à OVH de sortir l’instance de sa pause' do
    InstanceIa.reveiller

    assert_requested(:post, "#{INSTANCE_OVH}/unshelve", times: 1)
    assert_not_requested(:post, "#{INSTANCE_OVH}/shelve")
  end

  test 'la mise en pause demande à OVH de suspendre l’instance' do
    InstanceIa.mettre_en_pause

    assert_requested(:post, "#{INSTANCE_OVH}/shelve", times: 1)
    assert_not_requested(:post, "#{INSTANCE_OVH}/unshelve")
  end

  # ==================== TESTS CRITIQUES ====================
  # Réveiller l'instance engage une dépense : un appel mal signé est refusé par OVH, et une panne d'OVH doit arriver à
  # l'appelant sous une seule erreur, jamais comme un réveil réussi.
  test 'chaque appel porte les identifiants et la signature qu’attend l’API OVH (critique)' do
    travel_to Time.utc(2026, 10, 5, 14, 0, 0) do
      InstanceIa.reveiller

      horodatage = Time.utc(2026, 10, 5, 14, 0, 0).to_i.to_s
      signature = Digest::SHA1.hexdigest("secret-de-test+consommateur-de-test+POST+#{INSTANCE_OVH}/unshelve++#{horodatage}")
      assert_requested(:post, "#{INSTANCE_OVH}/unshelve",
                       headers: { 'X-Ovh-Application' => 'cle-de-test', 'X-Ovh-Consumer' => 'consommateur-de-test',
                                  'X-Ovh-Timestamp' => horodatage, 'X-Ovh-Signature' => "$1$#{signature}" })
    end
  end

  test 'un refus de l’API OVH lève une erreur qui porte son code (critique)' do
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_return(status: 409, headers: { 'Content-Type' => 'application/json' }, body: '{"message":"conflit"}')

    erreur = assert_raises(InstanceIa::Erreur) { InstanceIa.reveiller }

    assert_equal "l'API OVH répond 409", erreur.message
  end

  test 'une API OVH injoignable lève la même erreur (critique)' do
    stub_request(:get, INSTANCE_OVH).to_timeout

    assert_raises(InstanceIa::Erreur) { InstanceIa.etat }
  end

  test 'une demande restée sans réponse se distingue d’un refus : OVH a pu la prendre (critique)' do
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_timeout
    stub_request(:post, "#{INSTANCE_OVH}/shelve").to_return(status: 409)

    assert_raises(InstanceIa::SansReponse) { InstanceIa.reveiller }
    assert_not_kind_of InstanceIa::SansReponse, assert_raises(InstanceIa::Erreur) { InstanceIa.mettre_en_pause }
  end

  # ==================== /TESTS CRITIQUES ====================
end
