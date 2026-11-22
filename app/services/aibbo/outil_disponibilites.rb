# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit de la disponibilité des agents sur un créneau : les conflits que le formulaire d'intervention signale déjà.
  class OutilDisponibilites < Outil
    description "Dit quels intervenants des services de l'utilisateur (agents, managers et administrateurs, comme le formulaire d'intervention) " \
                'sont disponibles sur un créneau, ou à un instant, et, pour les autres, ' \
                'ce qui les retient : une intervention prévue ou réalisée, ou une absence. ' \
                "Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :debut, description: 'Début du créneau, au format AAAA-MM-JJ HH:MM'
      string :fin, required: false, description: "Fin du créneau, au format AAAA-MM-JJ HH:MM ; sans elle, la disponibilité à l'instant du début"
      string :service, required: false, description: "Nom du service, par exemple Technique ; sans lui, tous les services de l'utilisateur"
      string :agent, required: false, description: "Nom, prénom ou les deux, pour ne regarder qu'un seul agent"
    end

    def name
      'disponibilite_agents'
    end

    def execute(debut:, fin: nil, service: nil, agent: nil)
      debut = instant(debut)
      fin = fin.present? ? instant(fin) : debut
      raise Refus, 'La fin du créneau ne peut pas précéder son début.' if fin < debut

      services = @utilisateur.get_services_by_role
      services = [designe(services, service, 'service')] if service.present?
      agents = User.visible_to(@utilisateur).intervenants_pour(services).ordered
      agents = agents.where(id: designe(agents, agent, 'agent')) if agent.present?
      agents = agents.to_a

      occupations = Intervention.joins(:agent_interventions).where(agent_interventions: { agent_id: agents.map(&:id) })
                                .where(Intervention::OVERLAP_SQL, debut: debut, fin: fin)
                                .select('interventions.*, agent_interventions.agent_id AS agent_occupe_id')
      lisibles = Intervention.visible_to(@utilisateur).where(id: occupations.map(&:id)).ids
      raisons = Hash.new { |par_agent, agent_id| par_agent[agent_id] = [] }
      occupations.each do |intervention|
        quoi = lisibles.include?(intervention.id) ? "intervention « #{intervention.description} »" : "intervention d'un autre service"
        raisons[intervention.agent_occupe_id] << "#{quoi} du #{horodatage(intervention.effective_début)} au #{horodatage(intervention.effective_fin)}"
      end
      Absence.where(user_id: agents.map(&:id))
             .where(Intervention::ABSENCE_OVERLAP_SQL, debut: debut.to_date, fin: fin.to_date)
             .select { |absence| absence.couvre?(debut, fin) }.each do |absence|
        resume = absence.résumé
        raisons[absence.user_id] << "absence du #{resume['du']} au #{resume['au']} (#{[resume['période'], resume['motif']].compact.join(', ')})"
      end

      occupes, libres = agents.partition { |agent| raisons.key?(agent.id) }
      { debut: horodatage(debut), fin: horodatage(fin), services: services.map(&:nom),
        disponibles: libres.map { |agent| agent.nom_prénom.strip },
        indisponibles: occupes.map { |agent| { agent: agent.nom_prénom.strip, raisons: raisons[agent.id] } } }
    end
  end
end
