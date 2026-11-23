# frozen_string_literal: true

require 'test_helper'
require 'turbo/broadcastable/test_helper'

class AnnoncerEtatIaTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test 'une IA en pause est annoncée, avec le réveil au dépôt et la remise en pause après les analyses' do
    annonce = capture_turbo_stream_broadcasts(:etat_ia) { AnnoncerEtatIa.call('SHELVED_OFFLOADED') }.sole

    assert_equal %w[replace etat_ia], [annonce['action'], annonce['target']]
    assert_match "L'IA est en pause", annonce.to_html
    assert_match 'Un dépôt la réveille : comptez environ 30 minutes ; elle se remettra en pause dès la fin des analyses.', annonce.to_html
  end

  test 'une IA qui démarre est annoncée, avec les documents qui l’attendent' do
    annonce = capture_turbo_stream_broadcasts(:etat_ia) { AnnoncerEtatIa.call('UNSHELVING') }.sole

    assert_match "L'IA démarre", annonce.to_html
    assert_match "Les documents sont en attente d'analyse.", annonce.to_html
  end

  test 'une IA active efface l’annonce précédente, sans rien annoncer' do
    annonce = capture_turbo_stream_broadcasts(:etat_ia) { AnnoncerEtatIa.call('ACTIVE') }.sole

    assert_equal %w[replace etat_ia], [annonce['action'], annonce['target']]
    assert_empty Nokogiri::HTML5.fragment(annonce.to_html).text.strip
  end

  test 'une IA qui se met en pause est annoncée, avec le conseil d’attendre pour déposer' do
    annonce = capture_turbo_stream_broadcasts(:etat_ia) { AnnoncerEtatIa.call('SHELVING') }.sole

    assert_match "L'IA se met en pause", annonce.to_html
    assert_match "Attendez qu'elle le soit pour déposer : un document déposé maintenant passerait en échec.", annonce.to_html
  end

  test 'l’état gardé en cache est oublié, pour que la page rechargée relise OVH' do
    Rails.cache.stub(:delete, ->(clé) { @oubliée = clé }) do
      AnnoncerEtatIa.call('ACTIVE')
    end

    assert_equal InstanceIa::CACHE, @oubliée
  end
end
