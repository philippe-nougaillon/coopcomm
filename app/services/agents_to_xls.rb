class AgentsToXls < ExportToXls
  attr_reader :users
  private :users

  def initialize(agents)
    @agents = agents
  end

  def call

    headers = %w{Nom Prénom Email Service Nb_d'interventions Temps_total Nb_de_jours_d'absences }

    data = []

    @agents.each do |agent|
      interventions = agent.interventions

      temps_total = 0
      interventions.each do |intervention|
        temps_total += intervention.calc_temps_total
      end

      nb_jours_absences = agent.absences.count

      data << [
        agent.nom,
        agent.prénom,
        agent.email,
        agent.service,
        interventions.count,
        temps_total,
        nb_jours_absences
      ]
    end

    ExportToXls.new
               .add_worksheet("Liste des agents")
               .add_headers(headers)
               .setup_data(data)
               .build_file

  end

end