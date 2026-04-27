class WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[ show edit update destroy ]
  before_action :is_user_authorized
  before_action :set_form_variables, only: %i[ new edit create update ]

  # GET /warehouses or /warehouses.json
  # def index
  #   @warehouses = current_organisation.warehouses
  # end

  # GET /warehouses/1 or /warehouses/1.json
  def show
  end

  # GET /warehouses/new
  def new
    @warehouse = Warehouse.new
  end

  # GET /warehouses/1/edit
  def edit
  end

  # POST /warehouses or /warehouses.json
  def create
    @warehouse = Warehouse.new(warehouse_params)
    @warehouse.organisation = current_organisation

    respond_to do |format|
      if @warehouse.save
        format.html { redirect_to @warehouse, notice: "Site créé avec succès." }
        format.json { render :show, status: :created, location: @warehouse }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /warehouses/1 or /warehouses/1.json
  def update
    respond_to do |format|
      if @warehouse.update(warehouse_params)
        format.html { redirect_to @warehouse, notice: "Site modifié avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @warehouse }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @warehouse.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /warehouses/1 or /warehouses/1.json
  def destroy
    @warehouse.destroy!

    respond_to do |format|
      format.html { redirect_to admin_parametres_path, notice: "Site supprimé avec succès.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse
      @warehouse = Warehouse.find_by(slug: params.expect(:id))
      if @warehouse.nil?
        redirect_to root_path, alert: "Site introuvable"
      end
    end

    # Only allow a list of trusted parameters through.
    def warehouse_params
      params.expect(warehouse: [ :name, :address, :longitude, :latitude, user_ids: [] ])
    end

    def is_user_authorized
      authorize @warehouse ? @warehouse : Warehouse
    end

    def set_form_variables
      @users = User.filter_by_service(current_user.services).where.not(rôle: "adhérent").ordered
    end
end
