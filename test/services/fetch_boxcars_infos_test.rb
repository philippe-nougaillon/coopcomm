require "test_helper"

class FetchBoxcarsInfosTest < ActiveSupport::TestCase
  VARIABLES_ENV = %w[AI_PROVIDER AIBOT_MODEL OPENAI_ACCESS_TOKEN DEBUG_AIBOT].freeze

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    ENV["AI_PROVIDER"] = "openai"
    # Fixé ici : un modèle gpt-5 passerait par /v1/responses, que le stub ne couvre pas
    ENV["AIBOT_MODEL"] = "gpt-4o-mini"
    ENV["OPENAI_ACCESS_TOKEN"] = "jeton-de-test"
    @requetes_openai = []
  end

  teardown do
    # Si la variable d'environnement a été changée, on remet la valeur de base, sinon on supprime la clé
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  # ==================== TESTS CRITIQUES ====================
  test "une question sur les interventions remonte toutes les interventions, y compris celles sans service" do
    assert_equal Intervention.pluck(:id).sort, interventions_renvoyees_au_llm(users(:manager_marseille)).sort
  end
  # ==================== /TESTS CRITIQUES ====================

  private

  # Joue un échange complet avec le LLM simulé : le train choisit l'outil AIBBO, l'outil exécute un ARCode qui liste
  # les identifiants d'interventions, puis le train conclut. Rend les identifiants que l'outil a réellement renvoyés
  # (boxcars réduit un tableau d'un élément à cet élément, et un tableau vide à 0).
  def interventions_renvoyees_au_llm(utilisateur)
    stub_openai_repondant(
      "Action: AÏBBO\nAction Input: Quelles sont les interventions ?",
      "ARCode: Intervention.pluck(:id)",
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
      # Boxcars relance le LLM quand une réponse est refusée. Sans ce garde-fou, la réponse manquante devient une
      # StandardError que le client OpenAI maquille en « Connection error ». flunk lève une Exception, qui passe.
      reponses.shift || flunk("Appel OpenAI n°#{@requetes_openai.size} non prévu : Boxcars a refusé une réponse simulée")
    end
  end

  def derniere_requete_openai
    @requetes_openai.last
  end
end
