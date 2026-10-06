class RestoreNotNullOnServicesOrganisationId < ActiveRecord::Migration[8.1]
  def up
    change_column_null :services, :organisation_id, false
  end

  # La contrainte appartient à AddOrganisationToService : l'annulation ne la retire pas.
  def down; end
end
