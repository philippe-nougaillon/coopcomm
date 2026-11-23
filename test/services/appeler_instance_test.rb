# frozen_string_literal: true

require 'test_helper'

class AppelerInstanceTest < ActiveSupport::TestCase
  setup do
    @jeton_initial = ENV.fetch('JETON_INSTANCES', nil)
    ENV['JETON_INSTANCES'] = 'jeton-de-test'
  end

  teardown do
    ENV['JETON_INSTANCES'] = @jeton_initial
  end

  test 'la réponse de l’instance est rendue, demandée avec le jeton partagé' do
    auteurs = AppelerInstance.call('https://autre-instance.exemple.fr', '/copies_wiki/auteurs')

    assert_equal ['camille.martin@autre-instance.exemple.fr'], auteurs.pluck('email')
    assert_requested :get, 'https://autre-instance.exemple.fr/copies_wiki/auteurs',
                     headers: { 'Authorization' => 'Bearer jeton-de-test' }
  end

  test 'un corps est envoyé en JSON par une requête POST' do
    réponse = AppelerInstance.call('https://autre-instance.exemple.fr', '/copies_wiki', { auteur: 'camille.martin@autre-instance.exemple.fr' })

    assert_equal 'reserver-un-outil-copie', réponse['slug']
    assert_requested :post, 'https://autre-instance.exemple.fr/copies_wiki',
                     headers: { 'Authorization' => 'Bearer jeton-de-test', 'Content-Type' => 'application/json' },
                     body: { auteur: 'camille.martin@autre-instance.exemple.fr' }.to_json
  end

  test 'une instance qui refuse la demande lève une erreur qui donne son motif' do
    stub_request(:post, 'https://autre-instance.exemple.fr/copies_wiki')
      .to_return(status: 422, body: { erreur: 'auteur inconnu' }.to_json)

    erreur = assert_raises(AppelerInstance::Erreur) do
      AppelerInstance.call('https://autre-instance.exemple.fr', '/copies_wiki', { auteur: 'inconnu@exemple.fr' })
    end
    assert_equal 'autre-instance.exemple.fr a refusé la demande : auteur inconnu', erreur.message
  end

  test 'une réponse qui n’est pas du JSON lève une erreur lisible' do
    stub_request(:get, 'https://autre-instance.exemple.fr/copies_wiki/auteurs').to_return(status: 404, body: '<html></html>')

    erreur = assert_raises(AppelerInstance::Erreur) do
      AppelerInstance.call('https://autre-instance.exemple.fr', '/copies_wiki/auteurs')
    end
    assert_equal 'autre-instance.exemple.fr a rendu une réponse illisible (404)', erreur.message
  end

  test 'une instance qui ne répond pas lève une erreur lisible au lieu d’une exception réseau (critique)' do
    stub_request(:get, 'https://autre-instance.exemple.fr/copies_wiki/auteurs').to_timeout

    erreur = assert_raises(AppelerInstance::Erreur) do
      AppelerInstance.call('https://autre-instance.exemple.fr', '/copies_wiki/auteurs')
    end
    assert_match 'autre-instance.exemple.fr ne répond pas', erreur.message
  end
end
