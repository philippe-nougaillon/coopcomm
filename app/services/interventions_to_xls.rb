class InterventionsToXls < ApplicationService
  require 'spreadsheet'
  attr_reader :interventions
  private :interventions

  def initialize(interventions)
    @interventions = interventions
  end

  def call
    Spreadsheet.client_encoding = 'UTF-8'
  
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: @interventions.name
    bold = Spreadsheet::Format.new :weight => :bold, :size => 11

    headers = %w{ID Description Mots_clés Statut Adhérent Équipe Agent_1 Agent_2 Agent_3 Agent_4 Début Fin Pause(h) Temps_passé Commentaires Évaluation Avis Créé_le Modifiée_le}

    sheet.row(0).concat headers
    sheet.row(0).default_format = bold
    
    index = 1

    @interventions.each do |intervention|
      fields_to_export = [
        intervention.id,
        intervention.description,
        intervention.tag_list.join(', '),
        intervention.workflow_state.humanize,
        intervention.adherent.try(:nom_prénom),
        intervention.user.nom_prénom,
        intervention.agents.first.try(:nom_prénom),
        intervention.agents.offset(1).first.try(:nom_prénom),
        intervention.agents.offset(2).first.try(:nom_prénom),
        intervention.agents.offset(3).first.try(:nom_prénom),
        intervention.début ? I18n.l(intervention.début) : "",
        intervention.fin ? I18n.l(intervention.fin) : "",
        intervention.temps_de_pause,
        intervention.temps_total,
        intervention.commentaires,
        intervention.note,
        intervention.avis,
        I18n.l(intervention.created_at),
        I18n.l(intervention.updated_at),
      ]
      sheet.row(index).replace fields_to_export
      index += 1
    end

    file_contents = StringIO.new
    book.write file_contents # => Now file_contents contains the rendered file output
    return file_contents.string.force_encoding('binary')

  end

end