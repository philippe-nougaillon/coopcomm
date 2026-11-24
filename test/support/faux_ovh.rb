# frozen_string_literal: true

# L'API OVH de l'instance du modèle, jouée par WebMock : son état, son réveil, sa mise en pause. À brancher après le faux
# modèle, qui retire les variables OVH.
module FauxOvh
  INSTANCE_OVH = 'https://eu.api.ovh.com/v1/cloud/project/projet-de-test/instance/instance-de-test'
  VARIABLES_OVH = { 'OVH_APP_KEY' => 'cle-de-test', 'OVH_APP_SECRET' => 'secret-de-test', 'OVH_CONSUMER_KEY' => 'consommateur-de-test',
                    'OVH_PROJECT_ID' => 'projet-de-test', 'OVH_INSTANCE_ID' => 'instance-de-test' }.freeze

  def brancher_faux_ovh(etat)
    @variables_ovh_initiales = VARIABLES_OVH.keys.index_with { |nom| ENV.fetch(nom, nil) }
    VARIABLES_OVH.each { |nom, valeur| ENV[nom] = valeur }
    stub_etat_de_l_instance(etat)
    %w[unshelve shelve].each do |action|
      stub_request(:post, "#{INSTANCE_OVH}/#{action}").to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: 'null')
    end
  end

  def debrancher_faux_ovh
    @variables_ovh_initiales&.each { |nom, valeur| ENV[nom] = valeur }
  end

  def stub_etat_de_l_instance(etat)
    stub_request(:get, INSTANCE_OVH).to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { status: etat }.to_json)
  end
end
