# frozen_string_literal: true

# Appel de boxcars pour répondre aux demandes de l'utilisateur via AÏBBO
class FetchBoxcarsInfos < ApplicationService
  def initialize
    # Outils boxcars utilisé pour le train
    boxcars = [Boxcars::ActiveRecord.new(
                  name: "AÏBBO",
                  models: self.MODELS,
                  context: self.ACTIVERECORD_CONTEXT,
                  engine: get_engine
                )]

    # Train permet de rebondir sur les réponses du LLM pour avoir une réponse épurée pour l'utilisateur
    @boxcars_builder = Boxcars.train.new(boxcars: boxcars, engine: get_engine)
  end

  def call(current_user, user_request)
    # Lance le train Boxcars pour renvoyer la réponse du LLM
    { response: @boxcars_builder.run(self.REQUEST_CONTEXT(user_request, current_user)) }
  end

  def MODELS
    [User, Intervention]
  end

  def ACTIVERECORD_CONTEXT
    <<~ACTIVERECORD_CONTEXT
      Date now : #{DateTime.now}

      More User's descriptions here: #{self.user_semantic_informations}
      More Intervention's descriptions here: #{self.intervention_semantic_informations}
      
      Never answer a different question than the one asked.
      Do not replace the requested data with similar data from another model.
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

  def user_semantic_informations
    {
      rôle: {
        Description: "The field 'rôle' defines a kind of user. The 'rôle' named 'adhérent' is the user with many demands of interventions.",
        Model_specifications: "The field has only these valid values: #{User.rôles.keys}"
      },
      interventions_adherent: {
        Description: "Interventions requested by an adherent.",
        Model_specifications: "User has_many :interventions_adherent, class_name: :Intervention, foreign_key: :adherent_id"
      },
      nom: {
        Description: "The field nom is the last name of the user."
      },
      prénom: {
        Description: "The field prénom is the first name of the user. The 'rôle' named 'adhérent' has never 'prénom' defined."
      },
    }
  end

  def intervention_semantic_informations
    {
      workflow_state: {
        Description: "A 'workflow_state' define the statement of one Intervention.",
        Usage: "workflow_state='pointage activé' corresponds to a master Intervention",
        Model_specifications: "Column has valid values: #{Intervention.workflow_spec.state_names}"
      },
      adherent:  {
        Description: "An 'adherent' is a User how demand Interventions.",
        Model_specifications: "Intervention belongs_to :adherent, class_name: :User, foreign_key: :adherent_id"
      },
      description:  {
        Description: "A 'description' is the name of an Intervention. It may consist of a '#' symbol and numbers corresponding to an Intervention identifier."
      },
      début_prévue:  {
        Description: "The field 'début_prévue' is a date to plan an Intervention. To be used for an Intervention in the future."
      },
      fin_prévue:  {
        Description: "The field 'fin_prévue' is a date to plan an Intervention. To be used for an Intervention in the future."
      },
      début: {
        Description: "The field 'début' is a date defined by an 'agent' after doing an Intervention. To be used for an Intervention in the past."
      },
      fin: {
        Description: "The field 'fin' is a date defined by an 'agent' after doing an Intervention. To be used for an Intervention in the past."
      },
      template_slug: {
        Description: "Set only a slave (Intervention, named pointage). This slug corresponding of its master Intervention (workflow_state: 'pointage activé').
        The value is an opaque UUID, never a name or a description.",
        Usage: "Never compare 'template_slug' with a text. To get the slaves of a master Intervention with its name use: Intervention.find_by(workflow_state: 'pointage activé', description: 'Nettoyage').pointages",
      },
      temps_de_pause: {
        Description: "Break time indicated by an 'agent' after doing an Intervention"
      },
      temps_total: {
        Description: "Total time spent on an Intervention."
      }
    }
  end
end