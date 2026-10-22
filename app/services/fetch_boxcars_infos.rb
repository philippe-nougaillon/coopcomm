# frozen_string_literal: true

# Appel de boxcars pour répondre aux demandes de l'utilisateur via AÏBBO
class FetchBoxcarsInfos < ApplicationService
  def initialize
    # Utilisation de AÏKKU AI ou de GPT
    if ENV.fetch("AI_PROVIDER") == "vllm"
      engine = Boxcars::Ollama.new(uri_base: self.AIKKU_AI_URI_BASE, model: ENV.fetch("AIBOT_MODEL"))
    else
      engine = Boxcars::Openai.new(model: "gpt-4o-mini")
    end

    # Outils boxcars utilisé pour le train
    boxcars = [Boxcars::ActiveRecord.new(
                  name: "AÏBBO",
                  models: self.MODELS,
                  context: self.ACTIVERECORD_CONTEXT,
                  engine: engine
                )]

    # Train permet de rebondir sur les réponses du LLM pour avoir une réponse épurée pour l'utilisateur
    @boxcars_builder = Boxcars.train.new(boxcars: boxcars, engine: engine)
  end

  def call(current_user, request)
    limit_to_organisation(current_user.organisation)

    # Si le debug AÏBBO est activé, on créé un logger
    if ENV["DEBUG_AIBOT"] == "true"
      # Création d'un logger pour que Boxcars écrivent les logs dessus
      # Nécessaire à chaque call pour récupérer les logs juste pour cet appel 
      log_stream = StringIO.new
      origin_logger = Boxcars.configuration.logger
      Boxcars.configuration.logger = ActiveSupport::BroadcastLogger.new(
        ActiveSupport::TaggedLogging.new(Logger.new(log_stream)).tagged("AÏBBO"), 
        origin_logger
      )

      begin
        # Lance le train Boxcars pour récupérer la réponse
        response = @boxcars_builder.run(request + self.REQUEST_CONTEXT(current_user))
        succes = true
      rescue StandardError => e
        # Renvoie dans le logger Boxcars l'erreur de l'exception
        Boxcars.configuration.logger.error(e.full_message)
        succes = false
      ensure
        # Réattribution du logger Boxcars à celui de base
        Boxcars.configuration.logger = origin_logger
      end

      { response: response, log_stream: log_stream.string, succes: succes }
    else
      response = @boxcars_builder.run(request + self.REQUEST_CONTEXT(current_user))
      { response: response }
    end
  ensure
    remove_limit_to_organisation
  end

  def MODELS
    [User, InterventionForBoxcars]
  end

  def ACTIVERECORD_CONTEXT
    "
    Date now : #{DateTime.now},
    Intervention workflow states : #{Intervention.workflow_spec.state_names}
    "
  end

  def REQUEST_CONTEXT(current_user)
    "
    RÈGLES IMPORTANTES :
      - Tu dois TOUJOURS répondre par une phrase complète et naturelle en français à l'utilisateur.
      - Ne donne jamais un résultat brut (comme un simple chiffre ou une donnée JSON).
      - Après avoir trouvé l'information avec l'outil, reformule-la dans ta réponse finale.
      - Tu dois vouvoyer l'utilisateur

    Tu t'appelles #{User.find(ENV["UUID_AIBOT"]).nom}, l'utilisateur s'appelle #{current_user.nom_prénom}, il a le rôle #{current_user.rôle}.
    "
  end

  private

  # Configure le chemin vers AÏKKU AI
  def AIKKU_AI_URI_BASE
    "http://#{ENV.fetch('AIBOT_HOST')}:#{ENV.fetch('AIBOT_PORT')}/v1"
  end

  # Configure la variable organisation_id dans le thread SQL de l'utilisateur
  def limit_to_organisation(organisation)
    ActiveRecord::Base.lease_connection.execute(
      ActiveRecord::Base.sanitize_sql_array(["SELECT set_config('app.organisation_id', ?, false)", organisation.id.to_s])
    )
  end

  # Supprime la variable organisation_id du thread SQL
  def remove_limit_to_organisation
    ActiveRecord::Base.lease_connection.execute("RESET app.organisation_id")
  end
end