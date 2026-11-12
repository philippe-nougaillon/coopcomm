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

  # Chaque entrée suit le même gabarit, lu tel quel par le LLM :
  #   meaning     : ce que représente la donnée, et quand s'en servir
  #   values      : valeurs autorisées (colonnes à valeurs fermées)
  #   association : déclaration Rails (associations)
  #   usage       : exemple d'ARCode ou piège à éviter
  def user_semantic_informations
    {
      rôle: {
        meaning: "Kind of user. 'adhérent': member structure (client) that requests Interventions. " \
                  "'agent': field worker who performs Interventions. 'manager': manages one or more services in the organisation. " \
                  "'administrateur': manages the whole organisation.",
        values: User.rôles.keys,
        usage: "Each value is also a scope: User.adhérent, User.agent, User.manager, User.administrateur."
      },
      nom: {
        meaning: "Last name of the user, stored in uppercase. For an 'adhérent', it is the name of the member structure.",
        usage: "For a partial or case-insensitive match: User.where('nom ILIKE ?', '%dupont%')."
      },
      prénom: {
        meaning: "First name of the user. Always empty for an 'adhérent'."
      },
      interventions: {
        type: "association",
        meaning: "Interventions performed by the user as one of their agents (any rôle except 'adhérent'). " \
                  "Use it for questions about the work done by an agent.",
        association: "User has_many :interventions, through: :agent_interventions",
        usage: "User.find_by(nom: 'DUPONT').interventions"
      },
      interventions_adherent: {
        type: "association",
        meaning: "Interventions requested by the user as 'adhérent'. Use it for questions about the requests of an adhérent.",
        association: "User has_many :interventions_adherent, class_name: 'Intervention', foreign_key: :adherent_id",
        usage: "User.adhérent.find_by(nom: 'MAIRIE').interventions_adherent"
      }
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
      },
      agents: {
        Description: "An Intervention has many agents.",
        Usage: "To get the agents of an Intervention: Intervention.find_by(description: 'Nettoyage').agents",
        Model_specifications: "Intervention has_many :agents, through: :agent_interventions, class_name: 'User', dependent: :destroy"
      }
    }
  end
end