# frozen_string_literal: true

class OrganisationsController < ApplicationController
  before_action :demo_uniquement, only: :destroy

  def destroy
    authorize current_organisation
    SupprimerOrganisationJob.perform_later(current_organisation.id)
    sign_out
    redirect_to new_user_session_path, status: :see_other,
                notice: 'Au revoir ! Votre organisation sera supprimée dans quelques instants. Nous espérons vous revoir bientôt.'
  end

  def show
    authorize current_organisation
    @services_count = current_organisation.services.size
    @warehouses_count = current_organisation.warehouses.size
    @prestations_count = current_organisation.prestations.size
  end

  def edit
    authorize current_organisation
  end

  def update
    authorize current_organisation
    if current_organisation.update(organisation_params)
      redirect_to organisation_path, notice: 'Organisation modifiée avec succès.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  def purge_logo
    authorize current_organisation, :update?
    current_organisation.logo.purge
    current_organisation.update(audit_comment: 'Logo supprimé')
    redirect_to organisation_path, notice: 'Logo supprimé avec succès.', status: :see_other
  end

  private

  def organisation_params
    params.expect(organisation: %i[nom logo])
  end
end
