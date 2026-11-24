# frozen_string_literal: true

# Le serveur du modèle de langage, joué par WebMock sur un hôte qui n'existe pas : les tests laissent passer le
# réseau local, où LLM_HOST peut désigner le tunnel du vrai modèle.
module FauxModele
  ADRESSE_DU_MODELE = 'http://modele.test:8000'
  # Les variables OVH sont retirées : sans FauxOvh, l'instance du modèle ne se pilote pas, quoi que porte le .env du poste.
  VARIABLES_DU_MODELE = { 'LLM_HOST' => 'modele.test', 'LLM_PORT' => '8000', 'LLM_MODEL' => 'modele-de-test', 'LLM_TIMEOUT' => '30',
                          'OVH_APP_KEY' => nil, 'OVH_APP_SECRET' => nil, 'OVH_CONSUMER_KEY' => nil, 'OVH_PROJECT_ID' => nil,
                          'OVH_INSTANCE_ID' => nil }.freeze

  def brancher_faux_modele
    @variables_initiales = VARIABLES_DU_MODELE.keys.index_with { |nom| ENV.fetch(nom, nil) }
    VARIABLES_DU_MODELE.each { |nom, valeur| ENV[nom] = valeur }
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_return(status: 200, body: '{"status":"ok"}')
  end

  def debrancher_faux_modele
    @variables_initiales.each { |nom, valeur| ENV[nom] = valeur }
  end

  def stub_reponse_du_modele(*contenus)
    reponses = contenus.map do |contenu|
      { status: 200, headers: { 'Content-Type' => 'application/json' },
        body: { model: 'modele-de-test', choices: [{ finish_reason: 'stop', message: { role: 'assistant', content: contenu } }] }.to_json }
    end
    stub_request(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions").to_return(*reponses)
  end

  def corps_envoyes_au_modele
    corps = []
    assert_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions", at_least_times: 1) { |requete| corps << JSON.parse(requete.body) }
    corps
  end

  def corps_envoye_au_modele
    corps_envoyes_au_modele.last
  end
end
