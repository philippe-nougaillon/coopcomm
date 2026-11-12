# Éval d'AÏBBO contre le vrai LLM (payant, non déterministe), hors de test:all : bin/rails test test/evals/fetch_boxcars_infos_eval.rb
require "test_helper"

class FetchBoxcarsInfosEval < ActiveSupport::TestCase
  VARIABLES_ENV = %w[AI_PROVIDER].freeze
  ESSAIS = 3

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    ENV["AI_PROVIDER"] = "openai"
    assert ENV["AIBOT_MODEL"].present?, "AIBOT_MODEL absent de .env : le modèle d'AÏBBO est inconnu"
    assert ENV.values_at("OPENAI_ACCESS_TOKEN", "OPENAI_API_KEY").any?(&:present?), "clé OpenAI absente de .env"
    WebMock.disable_net_connect!(allow_localhost: true, allow: "api.openai.com")
  end

  teardown do
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  test "AÏBBO compte les interventions d'un agent dont le prénom est écrit sans accent" do
    attendu = users(:agent_marseille).interventions.count

    resultats = resultats_aibbo("Combien d'interventions a faites Rene ?")

    assert_equal [attendu] * ESSAIS, resultats.map { |resultat| resultat&.answer }, rapport_des_essais(resultats)
  end

  test "AÏBBO compte les pointages d'une intervention de pointage désignée par son titre" do
    maitresse = interventions(:intervention_repete)
    autre_maitresse = interventions(:nettoyage_port)
    maitresse.update_columns(workflow_state: Intervention::POINTAGE_ACTIVE)
    autre_maitresse.update_columns(workflow_state: Intervention::POINTAGE_ACTIVE)
    rattacher_en_pointage(interventions(:intervention_fille), maitresse)
    rattacher_en_pointage(interventions(:nouvelle_intervention), maitresse)
    rattacher_en_pointage(interventions(:intervention_paris), autre_maitresse)
    attendu = maitresse.pointages.count

    resultats = resultats_aibbo("Combien de pointages ont été faits sur l'intervention « #{maitresse.description} » ?")

    assert_equal [attendu] * ESSAIS, resultats.map { |resultat| resultat&.answer }, rapport_des_essais(resultats)
  end

  private

  # Un Boxcars::Result par essai (réponse et ARCode), nil quand l'outil abandonne après ses relances.
  # Chaque essai part d'un FetchBoxcarsInfos neuf : le boxcar garde dans son prompt les échanges de ses relances (B152).
  def resultats_aibbo(question)
    Array.new(ESSAIS) { outil_aibbo.run_result(question) }
  end

  # L'outil ActiveRecord tel que la production le construit (modèles, contexte, moteur), sans le train qui l'enrobe.
  def outil_aibbo
    FetchBoxcarsInfos.new.instance_variable_get(:@boxcars_builder).boxcars.first
  end

  # Message d'échec : l'ARCode et la réponse de chaque essai.
  def rapport_des_essais(resultats)
    resultats.map.with_index(1) do |resultat, numero|
      "Essai #{numero} : #{resultat&.added_context&.dig(:code).inspect} → #{resultat&.answer.inspect}"
    end.join("\n")
  end

  # Un pointage est une copie de sa maîtresse : même titre, et le slug de la maîtresse dans template_slug.
  def rattacher_en_pointage(intervention, maitresse)
    intervention.update_columns(template_slug: maitresse.slug, description: maitresse.description)
  end
end
