# frozen_string_literal: true

module ExportToXls
  # Génère un fichier XLS des quatre tuiles de l'accueil du tableau de bord, une feuille par tuile
  class Dashboard < ExportToXls::Base
    ETATS = [Intervention::NOUVEAU, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE].freeze

    def initialize(agents, donnees, conventions)
      super()
      @agents = agents
      @donnees = donnees
      @conventions = conventions
    end

    def call
      add_worksheet('Agents')
      add_headers(['Agent', 'Temps total', 'Interventions', 'Validées (%)', 'Note moyenne', 'Avis'])
      setup_data(@agents.map do |ligne|
        [ligne[:libellé], ligne[:temps], ligne[:nb],
         (ligne[:nb].positive? ? (100.0 * ligne[:validees] / ligne[:nb]).round : nil), ligne[:note], ligne[:avis]]
      end)

      # Le temps d'un mois : temps réel des interventions, plus la durée prévue des « nouveau », comme la courbe de la tuile.
      add_worksheet('Interventions')
      add_headers(['Service', 'Mois'] + ETATS.map(&:capitalize) + ['Temps total'])
      setup_data(par_service_et_mois do |service, mois|
        ETATS.map { |etat| @donnees[:etats][service][mois][etat] } +
          [(@donnees[:temps][service][mois] + @donnees[:prevus][service][mois]).round(1)]
      end)

      if @donnees[:reservations]
        add_worksheet("Outils #{@donnees[:annee]}")
        add_headers(%w[Jour Réservations])
        setup_data(@donnees[:reservations].sort.map { |jour, (nombre)| [jour, nombre] })
      end

      if @conventions
        add_worksheet('Conventions')
        add_headers(['Adhérent', 'Service', 'Du', 'Au', 'Heures conventionnées', 'Heures consommées', 'Heures prévues'])
        setup_data(@conventions.map do |convention|
          convention.values_at(:adherent, :service, :du, :au, :conventionnees, :consommees, :prevues)
        end)
      end

      add_worksheet('CRM')
      add_headers(%w[Service Mois Devis Commandes Factures])
      setup_data(par_service_et_mois { |service, mois| @donnees[:crm][service][mois].values_at(:devis, :commandes, :factures) })

      build_file
    end

    private

    def par_service_et_mois
      @donnees[:services].product(@donnees[:mois]).map { |service, mois| [service, mois, *yield(service, mois)] }
    end
  end
end
