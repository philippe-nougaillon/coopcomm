# frozen_string_literal: true

module ExportToXls
  # Génère un fichier XLS le dashboard d'un adherent
  class DashboardAdherent < ExportToXls::Base
    def initialize(proportion_temps_consomme, temps_total_par_mois, data_workflow_chart, qte_interventions_par_service,
                   temps_total_par_service, co2_total_par_mois)
      super()
      @proportion_temps_consomme = proportion_temps_consomme
      @temps_total_par_mois = temps_total_par_mois
      @data_workflow_chart = data_workflow_chart
      @qte_interventions_par_service = qte_interventions_par_service
      @temps_total_par_service = temps_total_par_service
      @co2_total_par_mois = co2_total_par_mois
    end

    def call
      add_worksheet('Temps consommé')
      add_headers(%w[Indicateur Temps])
      setup_data(@proportion_temps_consomme.to_a)

      add_worksheet('Temps par mois')
      add_headers(['Mois', 'Temps total'])
      setup_data(@temps_total_par_mois.to_a)

      add_worksheet('États par mois')

      labels = @data_workflow_chart[:labels]
      datasets = @data_workflow_chart[:datasets]

      # En-têtes : "Mois", "Nouveau", "Pointage_active", "Termine", etc.
      headers = ['Mois'] + datasets.map { |dataset| dataset[:label] }
      add_headers(headers)

      workflow_data = labels.each_with_index.map do |month, index|
        row = [month]
        datasets.each do |dataset|
          row << dataset[:data][index]
        end
        row
      end
      setup_data(workflow_data)

      add_worksheet('Qté par service')
      add_headers(%w[Service Quantité])
      setup_data(@qte_interventions_par_service.to_a)

      add_worksheet('Temps par service')
      add_headers(['Service', 'Temps total'])
      setup_data(@temps_total_par_service.to_a)

      add_worksheet('CO2 par mois')
      add_headers(['Mois', 'CO2 total'])
      setup_data(@co2_total_par_mois.to_a)

      build_file
    end
  end
end