class AgentsToXls < ApplicationService
  require 'spreadsheet'
  attr_reader :users
  private :users

  def initialize(agents)
    @agents = agents
  end

  def call

    Spreadsheet.client_encoding = 'UTF-8'

    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: "Liste des agents"
    bold = Spreadsheet::Format.new :weight => :bold, :size => 11

    headers = %w{Nom Prénom Email Service Nb_d'interventions Temps_total Nb_de_jours_d'absences }

    # Il faudrait son nom prénom email service, toutes les interventions qu'il a fait (base toi sur le champ fin),
    # de temps passé au total dans les interventions, et combien de jours d'absences il a eu.

    sheet.row(0).concat headers
    sheet.row(0).default_format = bold

    index = 1

    @agents.each do |agent|
      interventions = agent.interventions

      temps_total = 0
      interventions.each do |intervention|
        temps_total += intervention.calc_temps_total
      end

      nb_jours_absences = agent.absences.count

      fields_to_export = [
        agent.nom,
        agent.prénom,
        agent.email,
        agent.service,
        interventions.count,
        temps_total,
        nb_jours_absences
      ]
      sheet.row(index).replace fields_to_export
      index += 1
    end

    file_contents = StringIO.new
    book.write file_contents # => Now file_contents contains the rendered file output
    return file_contents.string.force_encoding('binary')

  end

end