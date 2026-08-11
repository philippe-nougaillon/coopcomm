# frozen_string_literal: true

# Construction déterministe des interventions servant aux matrices d'accès et de
# visibilité : les trois types du domaine, dans chacun des six états du workflow.
#
# Les enregistrements sont posés sans validation : les contrôles de disponibilité
# entreraient sinon en conflit avec les fixtures, et plusieurs états ne sont pas
# atteignables par une transition depuis `nouveau`.
#
# ⚠ Le trigger Postgres `interventions_refresh_dashboard` rafraîchit les deux vues
# matérialisées à CHAQUE écriture : au-delà d'une centaine d'écritures dans la même
# transaction, Postgres épuise `max_locks_per_transaction`. D'où `etat_en_memoire`,
# qui évite une écriture par état.
module InterventionsMatrice
  TYPES = %i[classique modele fille].freeze

  ETATS = [
    Intervention::NOUVEAU,
    Intervention::POINTAGE_ACTIVE,
    Intervention::TERMINE,
    Intervention::VALIDE,
    Intervention::REFUSE,
    Intervention::ARCHIVE
  ].freeze

  SLUG_MERE = 'matrice-modele-de-pointage'

  SONDE_COMMENTAIRES = 'SONDE-COMMENTAIRE-XYZ'
  SONDE_AVIS = 'SONDE-AVIS-XYZ'
  SONDE_METEO = 'SONDE-METEO-XYZ'

  def intervention_matrice(type:, etat: Intervention::NOUVEAU, agent: :defaut, adherent: nil,
                           service: nil, complete: false, description: nil)
    agent = users(:martin_technique_paris) if agent == :defaut

    attributs = {
      description: description || "Matrice #{type}",
      adherent: adherent || users(:weil),
      service: service || services(:technique),
      slug: SecureRandom.uuid,
      workflow_state: etat,
      repeter: type == :modele,
      template_slug: (type == :fille ? SLUG_MERE : nil)
    }
    intervention = Intervention.new(attributs)
    intervention.save!(validate: false)
    AgentIntervention.create!(agent: agent, intervention: intervention) if agent
    intervention.agents.reload
    # `update_columns` n'écrit pas d'audit : sans lui, l'historique d'activité
    # afficherait les sondes et fausserait la matrice de visibilité.
    intervention.update_columns(attributs_complets) if complete
    # Un modèle de pointage sauvegardé à l'état `terminé` en ressort à
    # « pointage activé » : after_commit → apres_terminaison → calculate_co2 fait
    # un `save` validé, qui rejoue check_workflow_pointage_mère. On force l'état
    # demandé pour que la matrice teste bien ce qu'elle annonce.
    intervention.update_columns(workflow_state: etat) if intervention.reload.workflow_state != etat
    intervention.reload
  end

  # Le modèle dont dépendent les interventions de type `fille`, résolu par
  # `Intervention#intervention_mère` via le slug.
  def mere_matrice(agent: :defaut)
    agent = users(:martin_technique_paris) if agent == :defaut

    mere = Intervention.new(
      description: 'Matrice modèle de pointage',
      adherent: users(:weil),
      service: services(:technique),
      slug: SLUG_MERE,
      workflow_state: Intervention::POINTAGE_ACTIVE,
      repeter: true
    )
    mere.save!(validate: false)
    AgentIntervention.create!(agent: agent, intervention: mere) if agent
    mere.agents.reload
    mere
  end

  # Pose l'état du workflow SANS écriture : la policy comme la gem `workflow`
  # lisent l'attribut en mémoire.
  def etat_en_memoire(intervention, etat)
    intervention.workflow_state = etat
    intervention
  end

  # Dates réelles, temps, commentaires et évaluation : chaque donnée sert de
  # sonde dans les matrices de visibilité.
  #
  # Chaque intervention occupe un jour distinct : elles partagent toutes le même
  # agent, et des dates identiques les rendraient mutuellement invalides
  # (`agents_must_be_available`), ce qui fausserait toute transition de workflow.
  def attributs_complets
    @jour_matrice = (@jour_matrice || Date.new(2023, 1, 1)) + 1.day
    {
      début: @jour_matrice.to_time + 8.hours + 30.minutes,
      fin: @jour_matrice.to_time + 17.hours + 30.minutes,
      temps_de_pause: 1,
      temps_total: 8,
      début_prévue: @jour_matrice.to_time + 8.hours,
      fin_prévue: @jour_matrice.to_time + 18.hours,
      commentaires: SONDE_COMMENTAIRES,
      avis: SONDE_AVIS,
      note: 4,
      meteo: SONDE_METEO
    }
  end
end
