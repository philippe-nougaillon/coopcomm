class ConventionsController < ApplicationController
  before_action :set_user
  before_action :set_convention, only: %i[update destroy]

  def create
    @convention = @user.conventions.build(convention_params)
    authorize @convention

    if @convention.save
      redirect_to user_path(@user), notice: "Convention enregistrée."
    else
      render turbo_stream: turbo_stream.replace(
        helpers.dom_id(@convention, :form),
        partial: "conventions/form",
        locals: { user: @user, convention: @convention, available_services: available_services }
      ), status: :unprocessable_entity
    end
  end

  def update
    authorize @convention

    if @convention.update(convention_params)
      redirect_to user_path(@user), notice: "Convention mise à jour."
    else
      render turbo_stream: turbo_stream.replace(
        helpers.dom_id(@convention, :form),
        partial: "conventions/form",
        locals: { user: @user, convention: @convention, available_services: [] }
      ), status: :unprocessable_entity
    end
  end

  def destroy
    authorize @convention
    @convention.destroy
    redirect_to user_path(@user), notice: "Convention supprimée."
  end

  private

  def set_user
    @user = User.find_by(slug: params[:user_id])
  end

  def set_convention
    @convention = @user.conventions.find(params[:id])
  end

  def convention_params
    params.require(:convention).permit(:service_id, :date_début, :date_fin_prévue, :document)
  end

  # Services de l'adhérent pour lesquels une convention peut encore être créée
  def available_services
    adherent_services = current_user.administrateur? ? @user.services.to_a : (@user.services & current_user.services)
    used_services = @user.conventions.map(&:service)
    (adherent_services - used_services).sort_by(&:nom)
  end
end
