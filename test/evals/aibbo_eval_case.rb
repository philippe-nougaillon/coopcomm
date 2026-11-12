# Base des évals d'AÏBBO contre le vrai LLM (payant, non déterministe), hors de test:all : PARALLEL_WORKERS=1 bin/rails test test/evals/*_eval.rb
require "test_helper"

class AibboEvalCase < ActiveSupport::TestCase
  VARIABLES_ENV = %w[AI_PROVIDER].freeze
  ESSAIS = 3

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    @logger_boxcars_initial = Boxcars.configuration.logger
    @log_generated_initial = Boxcars.configuration.log_generated
    ENV["AI_PROVIDER"] = "openai"
    assert ENV["AIBOT_MODEL"].present?, "AIBOT_MODEL absent de .env : le modèle d'AÏBBO est inconnu"
    assert ENV.values_at("OPENAI_ACCESS_TOKEN", "OPENAI_API_KEY").any?(&:present?), "clé OpenAI absente de .env"
    WebMock.disable_net_connect!(allow_localhost: true, allow: "api.openai.com")
    Boxcars.configuration.logger = nil
    Boxcars.configuration.log_generated = true
    normaliser_les_noms_comme_en_production
  end

  teardown do
    Boxcars.configuration.logger = @logger_boxcars_initial
    Boxcars.configuration.log_generated = @log_generated_initial
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  private

  # Les nombres (ou les booléens) de chaque réponse doivent valoir exactement [attendu] : un ARCode qui rend
  # [["Technique", 9]] répond 9 ; un ARCode qui rend plusieurs nombres, ou aucun, ne répond pas.
  def assert_aibbo_repond(attendu, question)
    resultats = resultats_aibbo(question)
    obtenus = resultats.map { |resultat| valeurs_comparables(resultat&.answer, attendu) }

    assert_equal [[attendu]] * ESSAIS, obtenus, rapport_des_essais(resultats)
  end

  # Chaque réponse doit citer chacun des textes attendus, sans tenir compte de la casse.
  def assert_aibbo_cite(textes, question)
    resultats = resultats_aibbo(question)
    manquants = resultats.map { |resultat| textes.reject { |texte| texte_de(resultat&.answer).include?(texte.downcase) } }

    assert_equal [[]] * ESSAIS, manquants, rapport_des_essais(resultats)
  end

  # Un Boxcars::Result par essai (réponse et ARCode), nil quand l'outil abandonne après ses relances.
  # Chaque essai part d'un FetchBoxcarsInfos neuf : le boxcar garde dans son prompt les échanges de ses relances (B152).
  # Boxcars écrit dans la console ce que le LLM génère, l'ARCode exécuté et ses relances ; le récapitulatif suit.
  def resultats_aibbo(question)
    puts "\n#{'=' * 100}\nQuestion : #{question}"
    resultats = Array.new(ESSAIS) do |indice|
      puts "--- Essai #{indice + 1}/#{ESSAIS}"
      outil_aibbo.run_result(question)
    end
    puts "--- Récapitulatif\n#{rapport_des_essais(resultats)}"
    resultats
  end

  # L'outil ActiveRecord tel que la production le construit (modèles, contexte, moteur), sans le train qui l'enrobe.
  def outil_aibbo
    FetchBoxcarsInfos.new.instance_variable_get(:@boxcars_builder).boxcars.first
  end

  # L'ARCode et la réponse de chaque essai.
  def rapport_des_essais(resultats)
    resultats.map.with_index(1) do |resultat, numero|
      "Essai #{numero} : #{resultat&.added_context&.dig(:code).inspect} → #{resultat&.answer.inspect}"
    end.join("\n")
  end

  # Les valeurs scalaires d'une réponse, quelle que soit sa forme (tableau, hash, enregistrement).
  def feuilles(valeur)
    case valeur
    when Array then valeur.flat_map { |element| feuilles(element) }
    when Hash then valeur.values.flat_map { |element| feuilles(element) }
    when ActiveRecord::Base then valeur.attributes.values
    else [valeur]
    end
  end

  # Les feuilles du même genre que la valeur attendue : booléens pour un booléen, nombres sinon.
  def valeurs_comparables(reponse, attendu)
    booleen = [true, false].include?(attendu)
    feuilles(reponse).select { |valeur| booleen ? [true, false].include?(valeur) : valeur.is_a?(Numeric) }
  end

  def texte_de(reponse)
    feuilles(reponse).map(&:to_s).join(" | ").downcase
  end

  # Les fixtures sont insérées sans passer par les `normalizes` des modèles, que la production applique à chaque
  # enregistrement comme à chaque recherche : `Tool.find_by(name: "tondeuse")` cherche "TONDEUSE".
  def normaliser_les_noms_comme_en_production
    User.unscoped.find_each do |utilisateur|
      utilisateur.update_columns(nom: User.normalize_value_for(:nom, utilisateur.nom),
                                 prénom: User.normalize_value_for(:prénom, utilisateur.prénom))
    end
    Service.find_each { |service| service.update_columns(nom: Service.normalize_value_for(:nom, service.nom)) }
    Tool.find_each { |outil| outil.update_columns(name: Tool.normalize_value_for(:name, outil.name)) }
  end
end
