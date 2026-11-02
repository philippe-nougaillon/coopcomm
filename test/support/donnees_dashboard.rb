# frozen_string_literal: true

# Données du tableau de bord partagées par ses tests de contrôleur : interventions avec un temps ou prévues,
# réservations de matériel, mois relatifs et ligne d'un agent dans l'activité des agents.
module DonneesDashboard
  def cree_intervention_avec_temps(temps, adherent:, service:, debut:, agent: nil)
    intervention = Intervention.create!(
      adherent: adherent,
      service: service,
      description: "Intervention de #{temps} h",
      début: debut,
      workflow_state: Intervention::VALIDE
    )
    intervention.update_columns(temps_total: temps)
    AgentIntervention.create!(agent: agent, intervention: intervention) if agent
    intervention
  end

  def cree_intervention_prevue(debut_prevu)
    Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Intervention planifiée',
                         début_prévue: debut_prevu, fin_prévue: debut_prevu + 2.hours, workflow_state: Intervention::NOUVEAU)
  end

  def reserve(outil, date, agent)
    Mouvement.create!(tool: outil, user: agent, état: :réservé, date: date)
  end

  def mois(n)
    n.months.ago.beginning_of_month.change(hour: 9) + 14.days
  end

  # La ligne d'un agent dans l'activité des agents, nil s'il n'y figure pas.
  def ligne_agent(agent)
    assigns(:activite_agents)[:lignes].find { |ligne| ligne[:agent] == agent }
  end
end
