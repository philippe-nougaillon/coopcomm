class InterventionsToXls < ApplicationService
  attr_reader :interventions
  private :interventions

  def initialize(interventions)
    @interventions = interventions
  end

  def call
    # Calculer le nombre maximum d'agents et d'outils (par défaut 0 si la liste est vide)
    max_agents = @interventions.map { |i| i.agents.count }.max || 0
    max_tools = @interventions.map { |i| i.tools.count }.max || 0

    # Construction dynamique des en-têtes
    base_headers_start = %w{ID Description Mots_clés Statut Adhérent}
    agent_headers = (1..max_agents).map { |i| "Agent_#{i}" }
    tool_headers = (1..max_tools).map { |i| "Outil_#{i}" }
    base_headers_end = %w{Début Fin Pause(h) Temps_passé Commentaires Évaluation Avis Créé_le Modifiée_le}

    headers = base_headers_start + agent_headers + tool_headers + base_headers_end

    data = []

    @interventions.each do |intervention|
      # On charge les relations en tableau pour lire facilement les index
      agents = intervention.agents.to_a
      tools = intervention.tools.to_a

      # Construction dynamique des colonnes avec le Safe Navigation Operator (&.)
      # S'il n'y a pas d'agent/outil à cet index, ça renverra nil (cellule vide dans Excel)
      agent_columns = max_agents.times.map { |index| agents[index]&.nom_prénom }
      tool_columns = max_tools.times.map { |index| tools[index]&.name }

      # Assemblage de la ligne
      row = [
        intervention.id,
        intervention.description,
        intervention.tag_list.join(', '),
        intervention.workflow_state.humanize,
        intervention.adherent.try(:nom_prénom)
      ] + 
      agent_columns + 
      tool_columns + 
      [
        intervention.début ? I18n.l(intervention.début) : "",
        intervention.fin ? I18n.l(intervention.fin) : "",
        intervention.temps_de_pause,
        intervention.temps_total,
        intervention.commentaires,
        intervention.note,
        intervention.avis,
        I18n.l(intervention.created_at),
        I18n.l(intervention.updated_at)
      ]

      data << row
    end

    ExportToXls.new
               .add_worksheet("Liste des interventions")
               .add_headers(headers)
               .setup_data(data)
               .build_file
  end
end