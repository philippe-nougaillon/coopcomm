# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'

class TranscrirePagesTest < ActiveSupport::TestCase
  include FauxModele

  setup do
    brancher_faux_modele
  end

  teardown do
    debrancher_faux_modele
  end

  test 'les transcriptions des pages se suivent dans l’ordre du document' do
    stub_reponse_du_modele('Texte de la première page', 'Texte de la seconde page')

    assert_equal "Texte de la première page\n\nTexte de la seconde page", TranscrirePages.call(%w[premiere seconde])
  end

  test 'chaque page part seule dans son appel, sans schéma de réponse' do
    stub_reponse_du_modele('Texte de la première page', 'Texte de la seconde page')

    TranscrirePages.call(%w[premiere seconde])

    corps = corps_envoyes_au_modele
    images = corps.map { |appel| appel['messages'].last['content'].filter_map { |partie| partie.dig('image_url', 'url') } }
    assert_equal [["data:image/jpeg;base64,#{Base64.strict_encode64('premiere')}"], ["data:image/jpeg;base64,#{Base64.strict_encode64('seconde')}"]], images
    assert(corps.none? { |appel| appel.key?('response_format') })
  end

  test 'un modèle injoignable interrompt la transcription (critique)' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    assert_raises(InterrogerIa::Indisponible) { TranscrirePages.call(%w[premiere seconde]) }
  end
end
