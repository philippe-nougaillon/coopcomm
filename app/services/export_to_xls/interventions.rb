# frozen_string_literal: true

module ExportToXls
  # Génère un fichier XLS des interventions
  class Interventions < ExportToXls::Base
    attr_reader :interventions

    def initialize(interventions, include_evaluation: true)
      super()
      @interventions = interventions
      @include_evaluation = include_evaluation
    end

    def call
      max_agents = @interventions.map { |i| i.agents.count }.max || 0
      max_tools = @interventions.map { |i| i.tools.count }.max || 0

      base_headers_start = ['ID', 'Description', 'Mots clés', 'Statut', 'Adhérent', 'Service']
      agent_headers = (1..max_agents).map { |i| "Agent #{i}" }
      tool_headers = (1..max_tools).map { |i| "Outil #{i}" }
      base_headers_end = ['Début', 'Fin', 'Pause (H)', 'Temps total passé (H)', 'Commentaires']
      base_headers_end += ['Évaluation', 'Avis'] if @include_evaluation
      base_headers_end += ['Créé le', 'Modifié le']

      headers = base_headers_start + agent_headers + tool_headers + base_headers_end

      data = []

      @interventions.each do |intervention|
        agents = intervention.agents.to_a
        tools = intervention.tools.to_a

        agent_columns = max_agents.times.map { |index| agents[index]&.nom_prénom }
        tool_columns = max_tools.times.map { |index| tools[index]&.name }

        row = [
          intervention.id,
          intervention.description,
          intervention.tag_list.join(', '),
          intervention.workflow_state.to_s.humanize,
          intervention.adherent.try(:nom_prénom),
          intervention.service.nom,
          agent_columns,
          tool_columns,
          intervention.début ? I18n.l(intervention.début) : '',
          intervention.fin ? I18n.l(intervention.fin) : '',
          intervention.temps_de_pause,
          intervention.temps_total,
          intervention.commentaires
      ].flatten
        row += [intervention.note, intervention.avis] if @include_evaluation
        row += [I18n.l(intervention.created_at), I18n.l(intervention.updated_at)]

        data << row
      end

      add_worksheet('Interventions')
      add_headers(headers)
      setup_data(data)
      build_file
    end
  end
end