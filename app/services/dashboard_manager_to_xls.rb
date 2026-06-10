# frozen_string_literal: true

class DashboardManagerToXls < ExportToXls
  # Ajout de data_workflow_chart en 3ème argument
  def initialize(temps_total_par_adherent, temps_total_par_agent, data_workflow_chart, qte_interventions_par_service,
                 temps_total_par_service, co2_total_par_mois)
    super()
    @temps_total_par_adherent = temps_total_par_adherent
    @temps_total_par_agent = temps_total_par_agent
    @data_workflow_chart = data_workflow_chart
    @qte_interventions_par_service = qte_interventions_par_service
    @temps_total_par_service = temps_total_par_service
    @co2_total_par_mois = co2_total_par_mois
  end

  def call
    # 1. Onglet : Temps total par adhérent
    add_worksheet('Temps par adhérent')
    add_headers(['Adhérent', 'Temps total'])
    setup_data(@temps_total_par_adherent.to_a)

    # 2. Onglet : Temps total par agent
    add_worksheet('Temps par agent')
    add_headers(['Agent', 'Temps total'])
    setup_data(@temps_total_par_agent.to_a)

    # 3. Onglet : Interventions par état et mois (Nouveau !)
    add_worksheet('États par mois')
    labels = @data_workflow_chart[:labels]
    datasets = @data_workflow_chart[:datasets]

    # En-têtes dynamiques basés sur les statuts
    headers = ['Mois'] + datasets.map { |dataset| dataset[:label] }
    add_headers(headers)

    # Reconstruction des lignes de données
    workflow_data = labels.each_with_index.map do |month, index|
      row = [month]
      datasets.each do |dataset|
        row << dataset[:data][index]
      end
      row
    end
    setup_data(workflow_data)

    # 4. Onglet : Quantité d'interventions par service
    add_worksheet('Qté par service')
    add_headers(%w[Service Quantité])
    setup_data(@qte_interventions_par_service.to_a)

    # 5. Onglet : Temps total par service
    add_worksheet('Temps par service')
    add_headers(['Service', 'Temps total'])
    setup_data(@temps_total_par_service.to_a)

    # 6. Onglet : CO2 total par mois
    add_worksheet('CO2 par mois')
    add_headers(['Mois', 'CO2 total'])
    setup_data(@co2_total_par_mois.to_a)

    build_file
  end
end
