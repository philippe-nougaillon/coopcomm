class RemoveOrganisationIdFromIntervention < ActiveRecord::Migration[8.0]
  def up
    # AJout d'un service par défaut si l'intervention n'en a pas
    Intervention.where(service_id: nil).find_each do |intervention|
      default_service = Service.first
      intervention.update_column(:service_id, default_service.id) if default_service
    end

    remove_column :interventions, :organisation_id, :bigint
  end

  def down
    add_column :interventions, :organisation_id, :bigint

    # Réinitialise les modèles pour s'assurer que la colonne est bien reconnue
    Intervention.reset_column_information

    Intervention.find_each do |intervention|
      if intervention.service.present?
        intervention.update_column(:organisation_id, intervention.service.organisation_id)
      end
    end
  end
end
