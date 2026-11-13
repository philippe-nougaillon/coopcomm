# Base des évals du LLM utilisé par AÏBBO
# Lancé séparement de test:all via la commande suivante: PARALLEL_WORKERS=1 bin/rails test test/evals/*_eval.rb
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

  # Vérifie une valeur exacte, nombre ou booléen
  # Utilisé par les questions du genre:
  # - "Combien d'interventions ... ?"
  # - "La tondeuse est-elle en panne ... ?"
  # Exemple:
  # Question: "Combien d'interventions ont été réalisés le mois dernier"
  # Réponse correcte: 25
  # Réponses fausses: [15, 1] ou nil.
  def assert_response_aibbo(attendu, question)
    resultats = aibbo_results(question)
    obtenus = resultats.map { |resultat| boolean_or_number(resultat&.answer, attendu) }

    assert_equal [[attendu]] * ESSAIS, obtenus, rapport_des_essais(resultats)
  end

  # Vérifie que la réponse contient chacun des textes attendus, sans tenir compte de la casse
  # Utilisé par les questions du genre:
  # - "Qui a travaillé sur l'intervention ... ?"
  # - "De quelle marque est la tondeuse ?"
  # Exemple:
  # Question: "Qui a réservé le rateau le 10 mars 2026 ?"
  # Texte attendu: ["MARTIN"]
  # Réponses correctes: "MARTIN", ["MARTIN", "Michel"] ou ["BOND", "MARTIN"]
  # Réponses fausses: ["BOND"] ou nil.
  def assert_response_aibbo_contain(textes, question)
    resultats = aibbo_results(question)
    # On ne garde, pour chaque essai, que les textes attendus qui ne sont pas dans la réponse : [] quand tout est cité
    manquants = resultats.map { |resultat| textes.reject { |texte| unify_array_to_string(resultat&.answer).include?(texte.downcase) } }

    assert_equal [[]] * ESSAIS, manquants, rapport_des_essais(resultats)
  end

  # Ecrit dans les logs les essais du LLM, ce qu'il génère comme réponse, ainsi que le récapitulatif.
  # Chaque essai part d'un FetchBoxcarsInfos neuf : le boxcar garde dans son prompt les échanges de ses relances.
  def aibbo_results(question)
    puts "\n#{'=' * 100}\nQuestion : #{question}"
    resultats = Array.new(ESSAIS) do |indice|
      puts "--- Essai #{indice + 1}/#{ESSAIS}"
      FetchBoxcarsInfos.new.get_tool_boxcars_AR.run_result(question)
    end
    puts "--- Récapitulatif\n#{rapport_des_essais(resultats)}"
    resultats
  end

  # L'ARCode et la réponse de chaque essai.
  def rapport_des_essais(resultats)
    resultats.map.with_index(1) do |resultat, numero|
      "Essai #{numero} : #{resultat&.added_context&.dig(:code).inspect} → #{resultat&.answer.inspect}"
    end.join("\n")
  end

  # Retourne les valeurs scalaires d'une réponse, quelle que soit sa forme (tableau, hash, enregistrement).
  # Exemples: 
  # - [["Tondeuse", 4]] -> ["Tondeuse", 4]
  # - { "Technique" => 9 } -> [9]
  def response_flatted(valeur)
    case valeur
    when Array then valeur.flat_map { |element| response_flatted(element) }
    when Hash then valeur.values.flat_map { |element| response_flatted(element) }
    when ActiveRecord::Base then valeur.attributes.values
    else [valeur]
    end
  end

  # Retourne les valeurs de la réponse du même type que la valeur attendue : booléens si on attend un booléen, nombres sinon
  # Exemples avec attendu = 4    : ["Tondeuse", 4] -> [4]    ; ["Mario", true] -> []
  # Exemples avec attendu = true : ["Mario", true] -> [true] ; ["Tondeuse", 4] -> []
  # TODO: Il faudrait peut etre forcer dans le contexte de AR de retourner uniquement un boolean si la question suppose un vrai ou faux
  def boolean_or_number(reponse, attendu)
    booleen = [true, false].include?(attendu)
    response_flatted(reponse).select { |valeur| booleen ? [true, false].include?(valeur) : valeur.is_a?(Numeric) }
  end

  # Retourne la réponse sous forme de string en minuscule
  def unify_array_to_string(reponse)
    response_flatted(reponse).map(&:to_s).join(" | ").downcase
  end

  # Normalisation des noms des différents fixtures des models utilisés, car ils ne sont pas normalisés par le model, comme en production.
  def normalize_forgotten_string_fixtures
    User.unscoped.find_each do |utilisateur|
      utilisateur.update_columns(nom: User.normalize_value_for(:nom, utilisateur.nom),
                                 prénom: User.normalize_value_for(:prénom, utilisateur.prénom))
    end
    Service.find_each { |service| service.update_columns(nom: Service.normalize_value_for(:nom, service.nom)) }
    Tool.find_each { |outil| outil.update_columns(name: Tool.normalize_value_for(:name, outil.name)) }
  end
end
