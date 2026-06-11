# frozen_string_literal: true

class ServicesController < ApplicationController
  before_action :set_service, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /services or /services.json
  # def index
  #   @services = current_user.services
  #   @users = User.filter_by_service(@services)

  #   if params[:search].present?
  #     @services = @services.where("nom ILIKE :search", {search: "%#{params[:search]}%"})
  #   end

  #   if params[:user_id].present?
  #     @services = @services.joins(:users).where(users: {id: params[:user_id]})
  #   end

  #   @services = @services.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
  #   @pagy, @services = pagy(@services, items: 10)
  # end

  # GET /services/1 or /services/1.json
  def show; end

  # GET /services/new
  def new
    @service = Service.new
  end

  # GET /services/1/edit
  def edit; end

  # POST /services or /services.json
  def create
    @service = Service.new(service_params)
    @service.organisation = current_organisation

    respond_to do |format|
      if @service.save
        # Attribution du nouveau service à l'utilisateur courant pour qu'il ait accès.
        current_user.services << @service
        format.html { redirect_to @service, notice: 'Service créé avec succès.' }
        format.json { render :show, status: :created, location: @service }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /services/1 or /services/1.json
  def update
    respond_to do |format|
      if @service.update(service_params)
        format.html { redirect_to @service, notice: 'Service modifié avec succès.', status: :see_other }
        format.json { render :show, status: :ok, location: @service }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @service.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /services/1 or /services/1.json
  def destroy
    @service.destroy!

    respond_to do |format|
      format.html { redirect_to admin_parametres_path, notice: 'Service supprimé avec succès.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_service
    @service = Service.find_by(slug: params.expect(:id))
    return unless @service.nil?

    redirect_to root_path, alert: 'Service introuvable'
  end

  # Only allow a list of trusted parameters through.
  def service_params
    params.expect(service: %i[nom calculate_distance])
  end

  def is_user_authorized
    authorize @service || Service
  end

  def sortable_columns
    ['services.nom']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'services.nom'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
