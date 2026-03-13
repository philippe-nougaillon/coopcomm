class DashboardManagerToXls < ExportToXls
  def initialize(temps_total_par_adherent, temps_total_par_agent, qte_interventions_par_service, temps_total_par_service, co2_total_par_mois)
    super()
    @temps_total_par_adherent = temps_total_par_adherent
    @temps_total_par_agent = temps_total_par_agent
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

    # 3. Onglet : Quantité d'interventions par service
    add_worksheet('Qté par service')
    add_headers(['Service', 'Quantité'])
    setup_data(@qte_interventions_par_service.to_a)

    # 4. Onglet : Temps total par service
    add_worksheet('Temps par service')
    add_headers(['Service', 'Temps total'])
    setup_data(@temps_total_par_service.to_a)

    # 5. Onglet : CO2 total par mois
    add_worksheet('CO2 par mois')
    add_headers(['Mois', 'CO2 total'])
    setup_data(@co2_total_par_mois.to_a)

    # Construit et retourne le fichier final
    build_file
  end
end