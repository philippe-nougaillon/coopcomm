# frozen_string_literal: true

# Appel de boxcars pour répondre aux demandes de l'utilisateur via AÏBBO
class FetchBoxcarsInfos < ApplicationService
  HISTORY_SIZE = 10

  def initialize
    # Outils boxcars utilisé pour le train
    boxcars = [get_tool_boxcars_AR]

    # Train permet de rebondir sur les réponses du LLM pour avoir une réponse épurée pour l'utilisateur
    @boxcars_builder = Boxcars.train.new(boxcars: boxcars, engine: get_engine)
  end

  def call(current_user, request_message)
    # Lance le train Boxcars pour renvoyer la réponse du LLM
    @boxcars_builder.prompt.add_history(history_lines(current_user, request_message))
    { response: @boxcars_builder.run(self.REQUEST_CONTEXT(request_message.message, current_user)) }
  end

  def get_tool_boxcars_AR
    Boxcars::ActiveRecord.new(
      name: "AÏBBO",
      models: self.MODELS,
      context: self.ACTIVERECORD_CONTEXT,
      engine: get_engine
    )
  end

  private

  def MODELS
    [User, Intervention, Service, Tool, Convention, Cotation, CotationLigne, Commande, CommandeLigne, Facture, FactureLigne]
  end

  def ACTIVERECORD_CONTEXT
    <<~ACTIVERECORD_CONTEXT
      Date now : #{DateTime.now}

      More User's descriptions here: #{self.user_semantic_informations}
      More Intervention's descriptions here: #{self.intervention_semantic_informations}
      More Service's descriptions here: #{self.service_semantic_informations}
      More Tool's descriptions here: #{self.tool_semantic_informations}
      More Convention's descriptions here: #{self.convention_semantic_informations}

      Cotation, Commande and Facture are the CRM documents: occasional, one-off work sold to an adhérent by a service.
      Each one is created from the previous one: Cotation (quote, 'devis') -> Commande (order) -> Facture (invoice).
      The new document copies adherent, service, intitulé, mémo, date_livraison_souhaitée and the lines of the previous one,
      but no column links one document to another: never look for a cotation_id on a Commande nor a commande_id on a Facture
      (the lignes do carry the id of their own document: cotation_lignes.cotation_id, commande_lignes.commande_id, facture_lignes.facture_id).
      Each document lists its own lines: the work ('prestations') the agents must carry out, with quantity and price.
      Soft-deleted documents have discarded_at set: always start from Cotation.kept, Commande.kept or Facture.kept.
      More Cotation's descriptions here: #{self.cotation_semantic_informations}
      More Commande's descriptions here: #{self.commande_semantic_informations}
      More Facture's descriptions here: #{self.facture_semantic_informations}

      Never answer a different question than the one asked.
      Do not replace the requested data with similar data from another model.
      A datetime column (e.g. Intervention début_prévue, fin_prévue, début, fin) holds a time, and a bare Date only matches midnight:
      to filter on a day, always use Date#all_day, e.g. Intervention.where(début_prévue: Date.new(2026, 3, 10).all_day).
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
        usage: "Each value is also a scope: User.adhérent, User.agent, User.manager, User.administrateur. " \
                "User.intervenants returns every user who can perform Interventions (agent, manager, administrateur)."
      },
      nom: {
        meaning: "Last name of the user, stored in uppercase. For an 'adhérent', it is the name of the member structure.",
        usage: "Never search a name with find_by(nom: ...) or where('nom ILIKE ...'): use User.search_with_generic_name, " \
                "which matches nom, prénom or both, ignoring case and accents. " \
                "'Est-ce qu'il y a un utilisateur qui s'appelle Mario ?' -> User.search_with_generic_name('mario').pluck(:nom, :prénom, :rôle)"
      },
      prénom: {
        meaning: "First name of the user. Always empty for an 'adhérent'."
      },
      interventions: {
        type: "association",
        meaning: "Interventions performed by the user as one of their agents (any rôle except 'adhérent'). ",
        association: "User has_many :interventions, through: :agent_interventions",
        usage: "To filter Interventions by the name of an agent, use Intervention.by_agent instead."
      },
      interventions_adherent: {
        type: "association",
        meaning: "Interventions requested by the user as 'adhérent'. Use it for questions about the requests of an adhérent.",
        association: "User has_many :interventions_adherent, class_name: 'Intervention', foreign_key: :adherent_id",
        usage: "To filter Interventions by the name of an adhérent, use Intervention.by_adherent instead."
      },
      services: {
        type: "association",
        meaning: "Services the user belongs to, whatever their rôle. A user can belong to several services.",
        association: "User has_many :services, through: :user_services",
        usage: "'Dans quel service travaille Mario ?' -> " \
                "User.search_with_generic_name('mario').joins(:services).pluck(:nom, :prénom, 'services.nom')"
      }
    }
  end

  def intervention_semantic_informations
    {
      workflow_state: {
        meaning: "Current state of the Intervention. 'nouveau': to do, not done yet. " \
                  "'pointage activé': master Intervention used for time tracking (see template_slug). " \
                  "'terminé': done by the agents, awaiting review. 'validé' / 'refusé': reviewed. 'archivé': archived.",
        values: Intervention.workflow_spec.state_names.map(&:to_s)
      },
      description:  {
        meaning: "Title of the Intervention. When created without a title, it is '#' followed by the Intervention id (e.g. '#42'). " \
                  "A pointage has the same title as its master: to find a master by its title, " \
                  "always add workflow_state: 'pointage activé'.",
      },
      début_prévue:  {
        meaning: "Planned start of the Intervention. Use it for questions about what is planned."
      },
      fin_prévue:  {
        meaning: "Planned end of the Intervention. Use it for questions about what is planned."
      },
      début: {
        meaning: "Actual start of the Intervention, filled in by an agent. Use it for questions about what has been done. " \
                  "Never in the future."
      },
      fin: {
        meaning: "Actual end of the Intervention, filled in by an agent. Use it for questions about what has been done. " \
                  "Never in the future. Empty on a pointage still in progress."
      },
      temps_de_pause: {
        meaning: "Break time in hours, filled in by an agent."
      },
      temps_total: {
        meaning: "Work time in hours, computed automatically: (fin - début - temps_de_pause) x number of agents. " \
                  "It is the time of all agents added together, and 0 when début or fin is empty.",
        usage: "Time of one agent on an Intervention: intervention.temps_par_agent (= temps_total / agents.count). " \
                "'Combien d'heures Mario a travaillé sur l'intervention Nettoyage ?' -> " \
                "Intervention.by_agent('mario').find_by(description: 'Nettoyage').temps_par_agent"
      },
      template_slug: {
        meaning: "Only set on a pointage: a time-tracking Intervention created by an agent from a master Intervention " \
                "('pointage activé'). It holds the slug of that master: an opaque UUID, never a name or a description." \
                "A master is not a pointage: never count masters to answer a question about pointages. ",
        usage: "Never compare template_slug with a text. A pointage has a template_slug, a master never has one. " \
                "All pointages: Intervention.where.not(template_slug: nil). " \
                "Pointages of a master: intervention.pointages. Master of a pointage: pointage.intervention_mère."
      },
      adherent: {
        type: "association",
        meaning: "User with the rôle 'adhérent' who requested the Intervention.",
        association: "Intervention belongs_to :adherent, class_name: 'User', foreign_key: :adherent_id",
        usage: "Intervention.find_by(description: 'Nettoyage').adherent"
      },
      agents: {
        type: "association",
        meaning: "Users who perform the Intervention. Usually 'agent', but a 'manager' or an 'administrateur' can also be one, " \
                  "so never filter them with User.agent.",
        association: "Intervention has_many :agents, through: :agent_interventions, class_name: 'User'",
        usage: "Intervention.find_by(description: 'Nettoyage').agents"
      },
      service: {
        type: "association",
        meaning: "Service in charge of the Intervention. The adhérent and every agent of the Intervention belong to this service. " \
                  "Empty only for a request received by email from an adhérent of several services, until an administrateur assigns it.",
        association: "Intervention belongs_to :service, optional: true",
        usage: "'Combien d'interventions pour le service ménage ?' -> " \
                "Intervention.where(service: Service.by_nom('menage')).count"
      },
      tools: {
        type: "association",
        meaning: "Tools ('matériel') booked for the Intervention, for the whole duration of the Intervention.",
        association: "Intervention has_many :tools, through: :tool_interventions",
        usage: "Intervention.find_by(description: 'Nettoyage').tools.pluck(:name)"
      },
      by_adherent: {
        type: "scope",
        meaning: "Interventions requested by the adhérents whose name matches, ignoring case and accents. " \
                  "Pass only the proper name, without generic words.",
        usage: "'Quelles interventions a demandées la mairie de Viarmes ?' -> Intervention.by_adherent('viarmes')"
      },
      by_agent: {
        type: "scope",
        meaning: "Interventions performed by the users whose nom, prénom or both match, ignoring case and accents.",
        usage: "'Combien d'interventions a fait Mario ?' -> Intervention.by_agent('mario').count. " \
                "'Est-ce que Mario est intervenu à Viarmes ?' -> Intervention.by_agent('mario').by_adherent('viarmes').exists?"
      },
      pointages: {
        type: "method",
        meaning: "Pointages of a master Intervention: the time-tracking Interventions that agents created from it.",
        usage: "'Combien de pointages sur l'intervention Nettoyage ?' -> " \
                "Intervention.find_by(workflow_state: 'pointage activé', description: 'Nettoyage').pointages.count. " \
                "'Combien de pointages ont été enregistrés en tout ?' -> Intervention.where.not(template_slug: nil).count"
      }
    }
  end

  def service_semantic_informations
    {
      nom: {
        meaning: "Name of the service: a department of the organisation in charge of one field of activity " \
                  "(e.g. 'Ménage', 'Périscolaire'). Accents are kept.",
        usage: "Never search a name with find_by(nom: ...) or where('nom ILIKE ...'): use Service.by_nom."
      },
      calculate_distance: {
        meaning: "When true, the travel distance and time to the adhérent are computed for the Interventions of this service."
      },
      interventions: {
        type: "association",
        meaning: "Interventions handled by the service. An Intervention belongs to one service at most (see Intervention service).",
        association: "Service has_many :interventions",
        usage: "'Combien d'interventions pour le périscolaire ?' -> " \
                "Service.by_nom('periscolaire').interventions.count"
      },
      users: {
        type: "association",
        meaning: "Members of the service, whatever their rôle. A user can belong to several services.",
        association: "Service has_many :users, through: :user_services",
        usage: "Adhérents of a service: service.users.adhérent. Users who can perform its Interventions: service.users.intervenants."
      },
      managers: {
        type: "association",
        meaning: "Members of the service with the rôle 'manager'. They handle many services, includes agents, tools, and interventions.",
        association: "Service has_many :managers, -> { manager }, through: :user_services, source: :user",
        usage: "Manager handle the service: service.managers"
      },
      by_nom: {
        type: "scope",
        meaning: "The single service whose name contains the given text, ignoring case and accents, or nil when none matches. " \
                  "Pass only the proper name, without generic words.",
        usage: "'Est-ce que le service ménage existe ?' -> Service.by_nom('menage').present?"
      }
    }
  end

  def tool_semantic_informations
    {
      name: {
        meaning: "Name of the tool or vehicle, called 'matériel' by the users (e.g. 'Tondeuse', 'Camion benne'). Case varies.",
        usage: "Never search a name with find_by(name: ...) or where('name ILIKE ...'): use Tool.by_nom."
      },
      description: {
        meaning: "Free notes on the tool: characteristics, accessories, conditions of use."
      },
      marque: {
        meaning: "Brand of the tool. Often empty."
      },
      modèle: {
        meaning: "Model of the tool. Often empty."
      },
      interventions: {
        type: "association",
        meaning: "Interventions the tool is booked for. The booking lasts as long as the Intervention: " \
                  "from début (or début_prévue when empty) to fin (or fin_prévue when empty).",
        association: "Tool has_many :interventions, through: :tool_interventions",
        usage: "Interventions using the tool: tool.interventions. " \
                "'Pour combien d'interventions le camion est-il réservé le 20 novembre ?' -> " \
                "Tool.by_nom('camion').first.interventions.where('COALESCE(début, début_prévue) <= ? AND COALESCE(fin, fin_prévue) >= ?', " \
                "Date.new(2026, 11, 20).end_of_day, Date.new(2026, 11, 20).beginning_of_day).count"
      },
      mouvements: {
        type: "association",
        meaning: "Day-by-day log of the tool: bookings made directly on the tool, breakdowns and repairs. " \
                  "Columns: date (a day, without time), état, user_id (who booked or declared), commentaires. " \
                  "user_id is an opaque id: to say who, never answer with user_id, always give the User's nom and prénom. " \
                  "état 'réservé': booked by user_id for that day. 'panne': broken from that day. 'fin_de_panne': repaired that day. " \
                  "A breakdown writes no mouvement on the following days: to know if a tool is broken on a day, " \
                  "never filter mouvements.panne by date, always call est_encore_en_panne_le.",
        association: "Tool has_many :mouvements",
        usage: "Each état is also a scope. " \
                "'Qui a réservé la tondeuse le 20 novembre ?' -> " \
                "User.where(id: Tool.by_nom('tondeuse').first.mouvements.réservé.where(date: Date.new(2026, 11, 20)).select(:user_id)).pluck(:nom, :prénom). " \
                "'Est-ce que la tondeuse est en panne le 20 novembre ?' -> Tool.by_nom('tondeuse').first.est_encore_en_panne_le(Date.new(2026, 11, 20)). " \
                "'Est-ce que la tondeuse est disponible le 20 novembre ?' -> Tool.by_nom('tondeuse').first.disponible_le?(Date.new(2026, 11, 20)): " \
                "'disponible' (available) means neither booked by a mouvement, nor broken, nor taken by an Intervention that day."
      },
      by_nom: {
        type: "scope",
        meaning: "Tools whose name contains the given text, ignoring case and accents. " \
                  "Pass only the proper name, without generic words.",
        usage: "'Est-ce que la tondeuse existe ?' -> Tool.by_nom('tondeuse').exists?"
      }
    }
  end

  def convention_semantic_informations
    {
      ref: {
        meaning: "Reference of the Convention, e.g. 'CONV-2026-3'. A Convention is a regular, recurring contract: " \
                  "the time a service spends at an adhérent's over a period. It is the frequent case, " \
                  "unlike the occasional CRM documents (Cotation, Commande, Facture)."
      },
      date_début: {
        meaning: "First day of the Convention (a day, without time)."
      },
      date_fin_prévue: {
        meaning: "Last day of the Convention (a day, without time). A Convention is current on a day " \
                  "when date_début <= day <= date_fin_prévue.",
        usage: "Current Conventions: Convention.where('date_début <= :d AND date_fin_prévue >= :d', d: Date.current)"
      },
      heures_conventionnees: {
        meaning: "Hours of work the service owes the adhérent over the whole Convention."
      },
      heures_consommees: {
        type: "method",
        meaning: "Hours already worked: sum of temps_total of the Interventions of the same adhérent and service " \
                  "that started between date_début and date_fin_prévue.",
        usage: "Never read the heures_consommees column in SQL (where, sum, order, pluck): it is never updated. " \
                "Always call the method on each record. Remaining hours: c.heures_conventionnees - c.heures_consommees."
      },
      mémo: {
        meaning: "Free notes on the Convention."
      },
      user: {
        type: "association",
        meaning: "The adhérent who signed the Convention. An adhérent has at most one Convention per service over a period.",
        association: "Convention belongs_to :user; User has_many :conventions",
        usage: "'Quelle convention a la mairie de Viarmes ?' -> " \
                "Convention.where(user: User.adhérent.search_with_generic_name('viarmes')).joins(:service).pluck(:ref, 'services.nom')"
      },
      service: {
        type: "association",
        meaning: "Service that provides the hours of the Convention.",
        association: "Convention belongs_to :service; Service has_many :conventions",
        usage: "Convention.where(service: Service.by_nom('menage'))"
      },
      interventions: {
        type: "method",
        meaning: "Interventions counted in the Convention: same adhérent, same service, début between date_début and date_fin_prévue.",
        usage: "convention.interventions.count"
      }
    }
  end

  def cotation_semantic_informations
    crm_document_semantic_informations(
      Cotation,
      "CO-2026-4",
      "Quote ('devis', 'cotation') proposed to the adhérent. First CRM document, a Commande is created from it.",
      "'créé': draft written by a manager or an administrateur, not visible to the adhérent yet. " \
      "'envoyé': sent to the adhérent, awaiting their answer. " \
      "'signé': signed online by the adhérent (see signee_le), awaiting validation by a manager or an administrateur. " \
      "'validé': accepted by the organisation, a Commande can be created from it. " \
      "'refusé': refused by the adhérent or by the organisation; it can be corrected and sent again ('envoyé') or archived. " \
      "'archivé': closed, final. " \
      "Transitions: créé -> envoyé; envoyé -> signé or refusé; signé -> validé or refusé; validé -> archivé; " \
      "refusé -> envoyé or archivé.",
      :cotation_lignes
    ).merge(
      signee_le: {
        meaning: "When the adhérent signed the Cotation online. Empty when not signed."
      }
    )
  end

  def commande_semantic_informations
    crm_document_semantic_informations(
      Commande,
      "CM-2026-2",
      "Order ('commande') created from a Cotation. Second CRM document, a Facture is created from it.",
      "'créé': draft, not visible to the adhérent yet. 'envoyé': sent to the adhérent, awaiting validation. " \
      "'validé': accepted, a Facture can be created from it. " \
      "'refusé': refused; it can be corrected and sent again ('envoyé') or archived. 'archivé': closed, final. " \
      "Transitions: créé -> envoyé; envoyé -> validé or refusé; validé -> archivé; refusé -> envoyé or archivé. " \
      "There is no 'signé' state on a Commande.",
      :commande_lignes
    )
  end

  def facture_semantic_informations
    crm_document_semantic_informations(
      Facture,
      "FA-2026-7",
      "Invoice ('facture') created from a Commande. Last CRM document.",
      "'créé': draft, not visible to the adhérent yet. 'envoyé': sent to the adhérent, awaiting validation. " \
      "'validé': accepted. 'refusé': refused; it can be corrected and sent again ('envoyé') or archived. " \
      "'archivé': closed, final. " \
      "Transitions: créé -> envoyé; envoyé -> validé or refusé; validé -> archivé; refusé -> envoyé or archivé. " \
      "There is no 'signé' and no 'payé' state on a Facture.",
      :facture_lignes
    )
  end

  # Gabarit commun à Cotation, Commande et Facture, qui partagent les mêmes colonnes
  def crm_document_semantic_informations(model, ref_example, document_meaning, states_meaning, lignes)
    {
      ref: {
        meaning: "Reference of the document, e.g. '#{ref_example}'. #{document_meaning}"
      },
      intitulé: {
        meaning: "Title of the document."
      },
      workflow_state: {
        meaning: states_meaning,
        values: model.workflow_spec.state_names.map(&:to_s)
      },
      total_ht: {
        meaning: "Total amount before tax, in euros: sum of total_ht of the lines.",
        usage: "Turnover of a service: #{model}.kept.where(service: Service.by_nom('menage')).sum(:total_ht)"
      },
      date_livraison_souhaitée: {
        meaning: "Day the adhérent wishes the work to be done. Often empty."
      },
      mémo: {
        meaning: "Free notes on the document."
      },
      adherent: {
        type: "association",
        meaning: "User with the rôle 'adhérent' the document is addressed to.",
        association: "#{model} belongs_to :adherent, class_name: 'User'; User has_many :#{model.name.underscore.pluralize}_adherent",
        usage: "#{model}.kept.where(adherent: User.adhérent.search_with_generic_name('viarmes'))"
      },
      service: {
        type: "association",
        meaning: "Service that provides the work.",
        association: "#{model} belongs_to :service; Service has_many :#{model.name.underscore.pluralize}"
      },
      lignes => {
        type: "association",
        meaning: "Lines of the document, one per prestation: intitulé (label of the work), qté (quantity), " \
                  "prix_ht (unit price before tax) and total_ht (= prix_ht x qté). " \
                  "Never use prestation_id nor the Prestation model: the label to give is the intitulé of the line.",
        association: "#{model} has_many :#{lignes}",
        usage: "'Que contient le document #{ref_example} ?' -> " \
                "#{model}.kept.find_by(ref: '#{ref_example}').#{lignes}.pluck(:intitulé, :qté, :total_ht)"
      }
    }
  end
  
  # Derniers échanges avec AÏBBO, mis au format que le train ZeroShot attend
  def history_lines(current_user, request_message)
    train = @boxcars_builder
    bot_id = ENV["UUID_AIBOT"]
    Message.where(from_id: current_user.id, to_id: bot_id)
          .or(Message.where(from_id: bot_id, to_id: current_user.id))
          .message
          .where(created_at: ...request_message.created_at) # exclut la question en cours
          .order(created_at: :desc).limit(HISTORY_SIZE).reverse
          .map do |m|
            if m.from_id == current_user.id
              [:user, "#{train.question_prefix}#{m.message}"]
            else
              [:assistant, "#{train.thought_prefix}I know the final answer\n#{train.final_answer_prefix}#{m.message}"]
            end
          end
  end
end