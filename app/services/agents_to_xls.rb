class AgentsToXls < ExportToXls
  attr_reader :agents
  private :agents

  def initialize(agents)
    @agents = agents.includes(:interventions, :absences, :services)
  end

def call
  headers = [
    "Nom", 
    "Prénom", 
    "Email", 
    "Service", 
    "Téléphone", 
    "Nombre d'interventions", 
    "Temps total", 
    "Jours d'absence"          
  ]

  data = []

  @agents.each do |agent|
    interventions = agent.interventions
    temps_total = interventions.sum(&:calc_temps_total)
    nb_jours_absences = agent.absences.sum(&:nb_jours)

    data << [
      agent.nom,
      agent.prénom,
      agent.email,
      agent.services.map(&:nom).join(', ').presence || "Aucun",
      agent.téléphone,
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