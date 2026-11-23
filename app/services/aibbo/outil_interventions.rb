# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit des interventions : le périmètre de la liste et les champs de la fiche, pour l'utilisateur qui pose la question.
  class OutilInterventions < Outil
    LIGNES = 20
    DATES = { 'réalisé' => 'début', 'prévu' => 'début_prévue' }.freeze
    REGROUPEMENTS = %w[service agent adherent etat mois].freeze
    TRIS = %w[interventions heures].freeze
    PART_DE_L_AGENT = 'interventions.temps_total / NULLIF((SELECT COUNT(*) FROM agent_interventions ' \
                      'WHERE agent_interventions.intervention_id = interventions.id), 0)'
    PERSONNE = "COALESCE(NULLIF(TRIM(CONCAT(%<table>s.nom, ' ', %<table>s.prénom)), ''), 'Compte désactivé')"

    description 'Compte les interventions, additionne leurs heures de travail et en donne la liste. ' \
                "Le périmètre est déjà celui de l'utilisateur : ses interventions pour un agent, ses demandes pour un adhérent, " \
                'ses services pour un manager. Tous les filtres sont facultatifs et se cumulent. ' \
                "Sans regrouper_par : le total, les heures et les #{LIGNES} interventions les plus récentes. " \
                'Avec regrouper_par : le nombre et les heures de chaque groupe, classés par trier_par, le premier groupe étant le plus élevé. ' \
                'Le résultat porte aussi la note moyenne donnée par les adhérents aux interventions validées ou refusées, sauf pour un agent. ' \
                "Avec le filtre agent, les heures sont celles de cet agent seul. Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false, description: 'Premier jour de la période, au format AAAA-MM-JJ'
      string :au, required: false, description: 'Dernier jour de la période, inclus, au format AAAA-MM-JJ'
      string :sur, required: false, enum: DATES.keys,
                   description: 'Date visée par la période : « réalisé » pour le début réel (ce qui a été fait, valeur par défaut), ' \
                                '« prévu » pour le début prévu (ce qui est planifié)'
      string :service, required: false, description: 'Nom du service, par exemple Technique'
      string :agent, required: false, description: "Nom, prénom ou les deux d'une personne qui réalise des interventions"
      string :adherent, required: false, description: "Nom de l'adhérent : la commune ou la structure qui a demandé l'intervention"
      string :etat, required: false, enum: Intervention.workflow_spec.state_names.map(&:to_s), description: "État de l'intervention"
      string :regrouper_par, required: false, enum: REGROUPEMENTS, description: 'Regroupement du décompte'
      string :trier_par, required: false, enum: TRIS,
                         description: 'Classement des groupes, du plus élevé au plus bas : « interventions » (valeur par défaut) ou « heures »'
    end

    def name
      'interventions'
    end

    def execute(du: nil, au: nil, sur: nil, service: nil, agent: nil, adherent: nil, etat: nil, regrouper_par: nil, trier_par: nil)
      raise Refus, "Le classement « #{trier_par} » n'existe pas : #{TRIS.to_sentence}." if trier_par.present? && TRIS.exclude?(trier_par)

      colonne = DATES.fetch(sur.presence || 'réalisé') { raise Refus, "« sur » vaut « réalisé » ou « prévu », pas « #{sur} »." }
      visibles = Intervention.visible_to(@utilisateur)
      interventions = visibles

      debut = jour(du)&.beginning_of_day
      fin = jour(au)&.end_of_day
      interventions = interventions.where(colonne => debut..fin) if debut || fin

      if service.present?
        interventions = interventions.where(service: designe(Service.where(id: visibles.select(:service_id)), service, 'service'))
      end
      if agent.present?
        agents = User.where(id: AgentIntervention.where(intervention_id: visibles.select(:id)).select(:agent_id))
                     .or(User.visible_to(@utilisateur).intervenants)
        interventions = interventions.where(id: AgentIntervention.where(agent: designe(agents, agent, 'agent')).select(:intervention_id))
      end
      if adherent.present?
        interventions = interventions.where(adherent: designe(User.where(id: visibles.select(:adherent_id)), adherent, 'adhérent'))
      end
      if etat.present?
        raise Refus, "L'état « #{etat} » n'existe pas." unless Intervention.workflow_spec.state_names.map(&:to_s).include?(etat)

        interventions = interventions.where(workflow_state: etat)
      end

      heures = agent.present? ? PART_DE_L_AGENT : 'interventions.temps_total'
      resultat = { total: interventions.count, heures: interventions.sum(Arel.sql(heures)).to_f.round(2) }
      unless @utilisateur.agent?
        resultat[:note_moyenne] = interventions.where(workflow_state: [Intervention::VALIDE, Intervention::REFUSE], note: 1..)
                                               .average(:note)&.to_f&.round(2)
      end

      if regrouper_par.present?
        groupes = groupes_par(regrouper_par, interventions, colonne)
        heures_des_groupes = groupes.sum(Arel.sql(agent.present? || regrouper_par == 'agent' ? PART_DE_L_AGENT : 'interventions.temps_total'))
        lignes = groupes.count.map do |nom, nombre|
          { regrouper_par => nom || 'Sans date', interventions: nombre, heures: heures_des_groupes[nom].to_f.round(2) }
        end
        resultat.merge(groupes: lignes.sort_by do |ligne|
          regrouper_par == 'mois' && trier_par.blank? ? ligne['mois'] : -ligne[(trier_par.presence || 'interventions').to_sym]
        end)
      else
        recentes = interventions.includes(:service, :organisation, :adherent, :agents, :tools)
                                .order(Arel.sql("interventions.#{colonne} DESC NULLS LAST")).limit(LIGNES)
        resultat.merge(liste_complète: resultat[:total] <= LIGNES, interventions: recentes.map { |intervention| ligne(intervention) })
      end
    end

    private

    def groupes_par(regrouper_par, interventions, colonne)
      case regrouper_par
      when 'service' then interventions.left_joins(:service).group("COALESCE(services.nom, 'Sans service')")
      when 'agent'
        interventions.joins(:agent_interventions).joins(comptes_actifs('agents', 'agent_interventions.agent_id'))
                     .group(format(PERSONNE, table: 'agents'))
      when 'adherent'
        interventions.joins(comptes_actifs('adherents', 'interventions.adherent_id')).group(format(PERSONNE, table: 'adherents'))
      when 'etat' then interventions.group(:workflow_state)
      when 'mois'
        interventions.group("to_char(interventions.#{colonne} AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}', 'YYYY-MM')")
      else raise Refus, "Le regroupement « #{regrouper_par} » n'existe pas : #{REGROUPEMENTS.to_sentence}."
      end
    end

    def comptes_actifs(table, cle)
      "LEFT JOIN users #{table} ON #{table}.id = #{cle} AND #{table}.discarded_at IS NULL"
    end

    def ligne(intervention)
      droits = InterventionPolicy.new(@utilisateur, intervention)
      ligne = { id: intervention.id, description: intervention.description, état: intervention.workflow_state,
                service: intervention.service&.nom, adhérent: intervention.adherent&.nom_prénom&.strip }
      if droits.voir_dates_prevues?
        ligne.merge!(début_prévu: horodatage(intervention.début_prévue), fin_prévue: horodatage(intervention.fin_prévue))
      end
      if droits.voir_assignation?
        ligne.merge!(agents: intervention.agents.map { |agent| agent.nom_prénom.strip }, matériel: intervention.tools.map(&:name))
      end
      if droits.voir_realisation? || droits.voir_temps?
        ligne.merge!(début: horodatage(intervention.début), fin: horodatage(intervention.fin), heures: intervention.temps_total.to_f)
      end
      ligne.merge!(note: intervention.note, avis: intervention.avis) if droits.voir_compte_rendu?
      ligne.compact
    end
  end
end
