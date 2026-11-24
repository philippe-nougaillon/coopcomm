# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'

class InterrogerIaTest < ActiveSupport::TestCase
  include FauxModele

  SCHEMA = { name: 'essai', schema: { type: 'object', properties: { heures: { type: %w[number null] } },
                                      required: %w[heures], additionalProperties: false } }.freeze

  setup do
    brancher_faux_modele
  end

  teardown do
    debrancher_faux_modele
  end

  test 'l’IA est configurée dès que LLM_HOST est renseigné' do
    assert InterrogerIa.configuree?
  end

  test 'l’IA n’est pas configurée sans LLM_HOST' do
    ENV['LLM_HOST'] = nil

    assert_not InterrogerIa.configuree?
  end

  test 'l’IA est disponible quand le serveur du modèle se dit prêt' do
    assert InterrogerIa.disponible?
  end

  test 'l’IA n’est pas disponible tant que le serveur charge son modèle' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_return(status: 503)

    assert_not InterrogerIa.disponible?
  end

  test 'l’IA n’est pas disponible quand le serveur est injoignable' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    assert_not InterrogerIa.disponible?
  end

  # ==================== TESTS CRITIQUES ====================
  # L'instance du GPU est éteinte hors des démonstrations : toute panne du modèle doit arriver à l'appelant sous
  # une seule erreur, vite, et sans qu'aucun document ne parte.
  test 'un serveur injoignable lève Indisponible sans rien envoyer au modèle (critique)' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    assert_raises(InterrogerIa::Indisponible) { interroger }
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  test 'un serveur muet lève Indisponible sans rien envoyer au modèle (critique)' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_timeout

    assert_raises(InterrogerIa::Indisponible) { interroger }
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  test 'un serveur qui charge encore son modèle lève Indisponible sans rien lui envoyer (critique)' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_return(status: 503, body: '{"error":{"code":503,"message":"Loading model"}}')

    erreur = assert_raises(InterrogerIa::Indisponible) { interroger }

    assert_equal 'le serveur du modèle répond 503', erreur.message
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la consigne part en rôle système et le contenu en rôle utilisateur' do
    stub_reponse_du_modele('{"heures": 120}')

    interroger

    assert_equal [{ 'role' => 'system', 'content' => 'Lis les heures.' }, { 'role' => 'user', 'content' => 'Volume annuel : 120 heures.' }],
                 corps_envoye_au_modele['messages']
  end

  test 'le schéma de réponse est imposé au modèle' do
    stub_reponse_du_modele('{"heures": 120}')

    interroger

    format_demande = corps_envoye_au_modele['response_format']
    assert_equal 'json_schema', format_demande['type']
    assert_equal SCHEMA[:schema].deep_stringify_keys, format_demande['json_schema']['schema']
  end

  test 'le modèle interrogé est celui de LLM_MODEL, sans aléa' do
    stub_reponse_du_modele('{"heures": 120}')

    interroger

    assert_equal 'modele-de-test', corps_envoye_au_modele['model']
    assert_equal 0, corps_envoye_au_modele['temperature']
  end

  test 'les pages jointes partent en images, dans l’ordre' do
    stub_reponse_du_modele('{"heures": 120}')

    InterrogerIa.call(consigne: 'Lis les heures.', contenu: 'Deux pages.', schema: SCHEMA, images: %w[premiere seconde])

    parties = corps_envoye_au_modele['messages'].last['content']
    assert_equal ["data:image/jpeg;base64,#{Base64.strict_encode64('premiere')}", "data:image/jpeg;base64,#{Base64.strict_encode64('seconde')}"],
                 parties.filter_map { |partie| partie.dig('image_url', 'url') }
  end

  test 'sans schéma, le texte répondu est rendu tel quel' do
    stub_reponse_du_modele('Texte de la page')

    assert_equal 'Texte de la page', InterrogerIa.call(consigne: 'Transcris.', contenu: 'Une page.')
    assert_not corps_envoye_au_modele.key?('response_format')
  end

  test 'sans schéma, un texte coupé par la limite de longueur est gardé' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                 body: { choices: [{ finish_reason: 'length', message: { role: 'assistant', content: 'Début de la page' } }] }.to_json)

    assert_equal 'Début de la page', InterrogerIa.call(consigne: 'Transcris.', contenu: 'Une page.')
  end

  test 'une réponse coupée par la limite de longueur est refusée' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                 body: { choices: [{ finish_reason: 'length', message: { role: 'assistant', content: '{"heures": 1' } }] }.to_json)

    erreur = assert_raises(InterrogerIa::Erreur) { interroger }

    assert_equal 'réponse coupée avant la fin', erreur.message
  end

  test 'la réponse du modèle est rendue décodée' do
    stub_reponse_du_modele('{"heures": 120}')

    assert_equal({ 'heures' => 120 }, interroger)
  end

  test 'une réponse vide est refusée' do
    stub_reponse_du_modele('')

    erreur = assert_raises(InterrogerIa::Erreur) { interroger }

    assert_equal 'réponse vide', erreur.message
  end

  # ==================== TESTS CRITIQUES ====================
  # Même contrat une fois le document parti : une panne en cours d'appel est une indisponibilité, et l'appel n'est
  # jamais rejoué (une seconde inférence sur un GPU partagé).
  test 'un modèle qui ne répond pas dans le délai lève Indisponible sans rejouer l’appel (critique)' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions").to_raise(Net::ReadTimeout)

    assert_raises(InterrogerIa::Indisponible) { interroger }
    assert_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions", times: 1)
  end

  test 'une connexion coupée pendant l’appel lève Indisponible (critique)' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions").to_raise(Errno::ECONNRESET)

    assert_raises(InterrogerIa::Indisponible) { interroger }
  end

  test 'un modèle déchargé pendant l’appel lève Indisponible (critique)' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
      .to_return(status: 503, headers: { 'Content-Type' => 'application/json' },
                 body: '{"error":{"code":503,"message":"Loading model","type":"unavailable_error"}}')

    assert_raises(InterrogerIa::Indisponible) { interroger }
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un refus du serveur est rapporté avec son message' do
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
      .to_return(status: 400, headers: { 'Content-Type' => 'application/json' },
                 body: '{"error":{"code":400,"message":"request (81162 tokens) exceeds the available context size (32768 tokens), try increasing it",' \
                       '"type":"exceed_context_size_error","n_prompt_tokens":81162,"n_ctx":32768}}')

    erreur = assert_raises(InterrogerIa::Erreur) { interroger }

    assert_not_kind_of InterrogerIa::Indisponible, erreur
    assert_includes erreur.message, 'exceeds the available context size'
  end

  test 'une réponse qui n’est pas du JSON est refusée sans que son contenu soit cité' do
    stub_reponse_du_modele('La commune de Testville dispose de 120 heures.')

    erreur = assert_raises(InterrogerIa::Erreur) { interroger }

    assert_equal 'réponse illisible', erreur.message
  end

  private

  def interroger
    InterrogerIa.call(consigne: 'Lis les heures.', contenu: 'Volume annuel : 120 heures.', schema: SCHEMA)
  end
end
