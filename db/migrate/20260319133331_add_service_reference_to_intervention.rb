class AddServiceReferenceToIntervention < ActiveRecord::Migration[8.0]
  def up
    # Ajout de la colonne (null: true par défaut car on doit backfiller les données)
    add_reference :interventions, :service, foreign_key: true, null: true

    # Rafraîchir le cache des colonnes pour pouvoir utiliser la nouvelle colonne immédiatement
    Intervention.reset_column_information

    # Mise à jour des données existantes par lots (find_each) pour ne pas saturer la RAM
    Intervention.find_each do |intervention|
      service = find_service_for(intervention)

      # update_column permet de sauvegarder sans déclencher les validations ni les callbacks (ni un nouvel audit)
      intervention.update_column(:service_id, service.id) if service.present?
    end
  end

  def down
    remove_reference :interventions, :service
  end


private

  def find_service_for(intervention)
    # 1. Le premier service trouvé parmi la liste des agents
    # On utilise .find pour s'arrêter au premier agent qui possède au moins un service
    agent_with_service = intervention.agents.includes(:services).find { |agent| agent.services.any? }
    return agent_with_service.services.first if agent_with_service

    # 2. S'il n'y a pas d'agent avec un service, on cherche le service de l'adhérent
    if intervention.adherent&.services&.any?
      return intervention.adherent.services.first
    end

    # 3. Sinon, on cherche le premier service du créateur de l'intervention
    # Grâce à la gem "audited", on récupère l'audit de création
    creation_audit = intervention.audits.find_by(action: 'create')
    creator = creation_audit&.user
    
    if creator&.services&.any?
      return creator.services.first
    end

    # Si vraiment aucun service n'est trouvé, on retourne nil
    # intervention.organisation.services.first
  end
end
