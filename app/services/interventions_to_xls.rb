class InterventionsToXls < ApplicationService
  attr_reader :interventions
  private :interventions

  def initialize(interventions)
    @interventions = interventions
  end

  def call
    headers = %w{ID Description Mots_clés Statut Adhérent Agent_1 Agent_2 Agent_3 Agent_4 Outil_1 Outil_2 Outil_3 Outil_4 Début Fin Pause(h) Temps_passé Commentaires Évaluation Avis Créé_le Modifiée_le}

    data = []

    @interventions.each do |intervention|
      data << [
        intervention.id,
        intervention.description,
        intervention.tag_list.join(', '),
        intervention.workflow_state.humanize,
        intervention.adherent.try(:nom_prénom),
        intervention.agents.first.try(:nom_prénom),
        intervention.agents.offset(1).first.try(:nom_prénom),
        intervention.agents.offset(2).first.try(:nom_prénom),
        intervention.agents.offset(3).first.try(:nom_prénom),
        intervention.tools.first.try(:name),
        intervention.tools.offset(1).first.try(:name),
        intervention.tools.offset(2).first.try(:name),
        intervention.tools.offset(3).first.try(:name),
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
    end

    ExportToXls.new
              .add_worksheet("Liste des interventions")
              .add_headers(headers)
              .setup_data(data)
              .build_file
  end

end