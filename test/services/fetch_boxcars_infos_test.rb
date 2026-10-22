require "test_helper"

class FetchBoxcarsInfosTest < ActiveSupport::TestCase
  VARIABLES_ENV = %w[AI_PROVIDER OPENAI_ACCESS_TOKEN DEBUG_AIBOT].freeze

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    ENV["AI_PROVIDER"] = "openai"
    ENV["OPENAI_ACCESS_TOKEN"] = "jeton-de-test"
    @requetes_openai = []
  end

  teardown do
    # Si la variable d'environnement a été changé, on remet la valeur de base, sinon on supprime la clé
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  # ==================== TESTS CRITIQUES ====================
  # Le cloisonnement entre organisations dérive des services : une question posée à AÏBBO ne doit jamais
  # remonter les interventions d'une autre commune.
  test "en mode debug, une question sur les interventions remonte toutes celles de l’organisation de l’utilisateur (critique)" do
    ENV["DEBUG_AIBOT"] = "true"
    utilisateur = users(:manager_marseille)
    interventions_attendues = Intervention.joins(:service)
                                          .where(services: { organisation_id: utilisateur.organisation.id })
                                          .pluck(:id)

    assert_equal interventions_attendues.sort, interventions_renvoyees_au_llm(utilisateur).sort
  end

  test "en mode debug, une question sur les interventions ne remonte aucune intervention d’une autre organisation (critique)" do
    ENV["DEBUG_AIBOT"] = "true"
    interventions_renvoyees = interventions_renvoyees_au_llm(users(:manager_paris))

    assert_not_empty interventions_renvoyees
    assert_not_includes interventions_renvoyees, interventions(:nettoyage_port).id
  end

  test "hors mode debug, une question sur les interventions remonte celles de l’organisation de l’utilisateur (critique)" do
    utilisateur = users(:manager_marseille)
    interventions_attendues = Intervention.joins(:service)
                                          .where(services: { organisation_id: utilisateur.organisation.id })
                                          .pluck(:id)

    assert_equal interventions_attendues.sort, interventions_renvoyees_au_llm(utilisateur).sort
  end

  test "après une question à AÏBBO, la connexion ne donne plus accès aux interventions de l’organisation de l’utilisateur (critique)" do
    interventions_renvoyees_au_llm(users(:manager_marseille))

    assert_equal 0, InterventionForBoxcars.count
  end

  test "sans organisation posée sur la connexion, aucune intervention n’est visible par AÏBBO (critique)" do
    assert_equal 0, InterventionForBoxcars.count
  end

  # ==================== /TESTS CRITIQUES ====================

  private

  # Joue un échange complet avec le LLM simulé : le train choisit l'outil AIBBO, l'outil exécute un ARCode qui liste
  # les identifiants d'interventions, puis le train conclut. Rend les identifiants que l'outil a réellement renvoyés
  # (boxcars réduit un tableau d'un élément à cet élément, et un tableau vide à 0).
  def interventions_renvoyees_au_llm(utilisateur)
    stub_openai_repondant(
      "Action: AIBOT\nAction Input: Quelles sont les interventions ?",
      "ARCode: InterventionForBoxcars.pluck(:id)",
      "Final Answer: Voici vos interventions."
    )

    FetchBoxcarsInfos.new.call(utilisateur, "Quelles sont les interventions ?")

    contenu = derniere_requete_openai["messages"].map { |message| message["content"] }.join("\n")
    Array(JSON.parse(contenu.scan(/^Observation: (.*)$/).last.first))
  end

  # Chaque appel que fait Boxcars à l'API OpenAI reçoit la réponse suivante de la liste ; le corps des requêtes est conservé.
  def stub_openai_repondant(*contenus)
    reponses = contenus.map do |contenu|
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          choices: [{ index: 0, message: { role: "assistant", content: contenu }, finish_reason: "stop" }],
          usage: { prompt_tokens: 1, completion_tokens: 1, total_tokens: 2 }
        }.to_json
      }
    end

    stub_request(:post, "https://api.openai.com/v1/chat/completions").to_return do |requete|
      @requetes_openai << JSON.parse(requete.body)
      reponses.shift
    end
  end

  def derniere_requete_openai
    @requetes_openai.last
  end
end
