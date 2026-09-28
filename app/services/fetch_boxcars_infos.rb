# frozen_string_literal: true

# Prototype de l'appel de boxcars, en développement
class FetchBoxcarsInfos < ApplicationService
  def initialize
    if ENV.fetch("AI_PROVIDER") == "vllm"
      engine = Boxcars::Ollama.new(uri_base: self.AIBOT_URI_BASE, model: ENV.fetch("AIBOT_MODEL"))
    else
      engine = Boxcars::Openai.new(model: "gpt-5.5")
    end

    # Outil boxcars utilisé pour la requete
    boxcars = [Boxcars::ActiveRecord.new(
                  name: "AIBOT",
                  models: self.MODELS,
                  context: self.CONTEXT_ACTIVERECORD,
                  engine: engine
                )]

    # Train permet de rebondir sur ses propres réponses pour épurer la réponse
    @boxcars_builder = Boxcars.train.new(boxcars: boxcars, engine: engine)
  end

  def call(current_user, request)
    ENV["ORGANISATION_ID_FOR_BOXCARS"] = current_user.organisation.id.to_s

    if ENV["DEBUG_AIBOT"] == "true"
      # Création d'un logger pour que boxcars écrivent les logs dessus
      # Nécessaire à chaque call pour récupérer les logs juste pour cet appel 
      log_stream = StringIO.new
      origin_logger = Boxcars.configuration.logger
      Boxcars.configuration.logger = ActiveSupport::BroadcastLogger.new(ActiveSupport::TaggedLogging.new(Logger.new(log_stream)).tagged("AIBOT"), origin_logger)

      begin
        response = @boxcars_builder.run(request + self.CONTEXT_REQUEST(current_user))
        succes = true
      rescue StandardError => e
        Boxcars.configuration.logger.error(e.full_message(highlight: true))
        succes = true
      ensure
        Boxcars.configuration.logger = origin_logger
      end

      { response: response, log_stream: log_stream.string, succes: succes }
    else
      response = @boxcars_builder.run(request + self.CONTEXT_REQUEST(current_user))
      { response: response }
    end
  end

  def MODELS
    [User, InterventionForBoxcars, AgentIntervention]
  end

  def CONTEXT_ACTIVERECORD
    "
    Intervention belongs_to :agent, class_name: 'User'
    "
  end

  def CONTEXT_REQUEST(current_user)
    "
    RÈGLES IMPORTANTES :
      - Tu dois TOUJOURS répondre par une phrase complète et naturelle en français à l'utilisateur.
      - Ne donne jamais un résultat brut (comme un simple chiffre ou une donnée JSON).
      - Après avoir trouvé l'information avec l'outil, reformule-la dans ta réponse finale.
      - Tu dois vouvoyer l'utilisateur
    " +
    "
    Tu t'appelles AIBOT, l'utilisateur s'appelle #{current_user.nom_prénom}, il a le rôle #{current_user.rôle}. 
    Les attributs de l'utilisateur sont : \n #{current_user.inspect}
    "
  end

  private

  def AIBOT_URI_BASE
    "http://#{ENV.fetch('AIBOT_HOST')}:#{ENV.fetch('AIBOT_PORT')}/v1"
  end
end