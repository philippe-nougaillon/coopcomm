# frozen_string_literal: true

require 'test_helper'
require 'turbo/broadcastable/test_helper'
require_relative '../support/faux_modele'
require_relative '../support/faux_ovh'

class SurveillerIaJobTest < ActiveJob::TestCase
  include Turbo::Broadcastable::TestHelper
  include FauxModele
  include FauxOvh

  setup do
    brancher_faux_modele
    brancher_faux_ovh('ACTIVE')
    travel_to Time.utc(2026, 10, 5, 13)
  end

  teardown do
    debrancher_faux_ovh
    debrancher_faux_modele
  end

  # ==================== TESTS CRITIQUES ====================
  # L'IA réveillée par CoopComm est facturée à l'heure : elle est remise en pause dès qu'aucune analyse n'attend plus,
  # jamais tant qu'une analyse, d'où qu'elle vienne, l'attend encore.
  test 'la surveillance revient une minute plus tard tant qu’une analyse attend, sans mettre l’IA en pause (critique)' do
    SurveillerIaJob.perform_now

    assert_enqueued_with(job: SurveillerIaJob, at: 1.minute.from_now)
    assert_not_requested(:post, "#{INSTANCE_OVH}/shelve")
  end

  test 'l’IA est mise en pause dès qu’aucune analyse n’attend plus, et la surveillance s’arrête (critique)' do
    Convention.en_analyse.destroy_all

    SurveillerIaJob.perform_now

    assert_requested(:post, "#{INSTANCE_OVH}/shelve", times: 1)
    assert_no_enqueued_jobs only: SurveillerIaJob
  end

  test 'une analyse bloquée depuis plus de deux heures ne garde pas l’IA allumée (critique)' do
    Convention.en_analyse.where.not(id: conventions(:analyse_en_attente).id).destroy_all

    travel_to Time.utc(2026, 10, 5, 14, 1) do
      SurveillerIaJob.perform_now
    end

    assert_requested(:post, "#{INSTANCE_OVH}/shelve", times: 1)
  end

  test 'une mise en pause refusée par OVH est retentée (critique)' do
    Convention.en_analyse.destroy_all
    stub_request(:post, "#{INSTANCE_OVH}/shelve").to_return(status: 500)

    SurveillerIaJob.perform_now

    assert_enqueued_jobs 1, only: SurveillerIaJob
  end

  test 'la surveillance attend la fin du démarrage de l’IA avant de la mettre en pause (critique)' do
    Convention.en_analyse.destroy_all
    stub_etat_de_l_instance('UNSHELVING')

    SurveillerIaJob.perform_now

    assert_not_requested(:post, "#{INSTANCE_OVH}/shelve")
    assert_enqueued_with(job: SurveillerIaJob, at: 1.minute.from_now)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une IA déjà mise en pause ailleurs n’est pas remise en pause, et la surveillance s’arrête' do
    Convention.en_analyse.destroy_all
    stub_etat_de_l_instance('SHELVED_OFFLOADED')

    SurveillerIaJob.perform_now

    assert_not_requested(:post, "#{INSTANCE_OVH}/shelve")
    assert_no_enqueued_jobs only: SurveillerIaJob
  end

  test 'une IA qui se met déjà en pause n’est pas remise en pause, et la surveillance s’arrête' do
    Convention.en_analyse.destroy_all
    stub_etat_de_l_instance('SHELVING')

    SurveillerIaJob.perform_now

    assert_not_requested(:post, "#{INSTANCE_OVH}/shelve")
    assert_no_enqueued_jobs only: SurveillerIaJob
  end

  test 'la mise en pause de l’IA est annoncée sur la page d’analyse' do
    Convention.en_analyse.destroy_all

    annonces = capture_turbo_stream_broadcasts(:etat_ia) { SurveillerIaJob.perform_now }

    assert_match "L'IA se met en pause", annonces.sole.to_html
  end
end
