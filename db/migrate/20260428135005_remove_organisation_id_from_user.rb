class RemoveOrganisationIdFromUser < ActiveRecord::Migration[8.0]
  def up
    # AJout d'un service par défaut si l'utilisateur n'en a pas
    User.joins(user_services: :service).where(services: nil).find_each do |user|
      default_service = Service.first
      user.services << default_service if default_service
    end

    remove_column :users, :organisation_id, :bigint
  end

  def down
    add_column :users, :organisation_id, :bigint

    # Réinitialise les modèles pour s'assurer que la colonne est bien reconnue
    User.reset_column_information

    User.find_each do |user|
      if user.services.any?
        user.update_column(:organisation_id, user.services.first.organisation_id)
      else
        user.update_column(:organisation_id, Organisation.first.id)
      end
    end
  end
end
