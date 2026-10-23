# frozen_string_literal: true

# Appel de boxcars pour répondre aux demandes de l'utilisateur via AÏBBO
class FetchBoxcarsInfos < ApplicationService
  def initialize
    engine = get_engine

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

  def call(current_user, user_request)
    limit_to_organisation(current_user.organisation)

    # Lance le train Boxcars pour renvoyer la réponse du LLM
    { response: @boxcars_builder.run(self.REQUEST_CONTEXT(user_request, current_user)) }
  ensure
    remove_limit_to_organisation
  end

  def MODELS
    [User, InterventionForBoxcars]
  end

  def ACTIVERECORD_CONTEXT
    <<~ACTIVERECORD_CONTEXT
      Date now : #{DateTime.now}
      Intervention workflow states : #{Intervention.workflow_spec.state_names}
    
      Never answer a different question than the one asked: do not replace the requested data with similar data from another model.
      

    ACTIVERECORD_CONTEXT
  end

  def REQUEST_CONTEXT(user_request, current_user)
    <<~REQUEST_CONTEXT
    Question de l'utilisateur: #{user_request}

    RÈGLES IMPORTANTES:
      - Tu dois TOUJOURS répondre par une phrase complète et naturelle en français à l'utilisateur.
      - Ne donne jamais un résultat brut (comme un simple chiffre ou une donnée JSON).
      - Après avoir trouvé l'information avec l'outil, reformule-la dans ta réponse finale.
      - Tu dois vouvoyer l'utilisateur

    Tu t'appelles #{User.find(ENV["UUID_AIBOT"]).nom}, l'utilisateur s'appelle #{current_user.nom_prénom}, il a le rôle #{current_user.rôle}.
    REQUEST_CONTEXT
  end

  private

  # Utilisation de AÏKKU AI ou de GPT
  def get_engine
    if ENV.fetch("AI_PROVIDER") == "vllm"
      Boxcars::Ollama.new(uri_base: self.AIKKU_AI_URI_BASE, model: ENV.fetch("AIBOT_MODEL"))
    else
      Boxcars::Openai.new(model: ENV.fetch("AIBOT_MODEL"))
    end
  end

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