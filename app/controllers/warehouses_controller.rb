class WarehousesController < ApplicationController
  before_action :set_warehouse, only: %i[ show edit update destroy ]
  before_action :is_user_authorized
  before_action :set_organisation_user_tags, only: [:new, :create, :edit, :update]

  # GET /warehouses or /warehouses.json
  # def index
  #   @warehouses = current_user.organisation.warehouses
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
    @warehouse.organisation = current_user.organisation

    respond_to do |format|
      if @warehouse.save
        format.html { redirect_to @warehouse, notice: "Entrepôt créé avec succès." }
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
        format.html { redirect_to @warehouse, notice: "Entrepôt modifié avec succès.", status: :see_other }
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
      format.html { redirect_to admin_parametres_path, notice: "Entrepôt supprimé avec succès.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_warehouse
      @warehouse = Warehouse.find_by(slug: params.expect(:id))
      if @warehouse.nil?
        redirect_to root_path, alert: "Entrepôt introuvable"
      end
    end

    # Only allow a list of trusted parameters through.
    def warehouse_params
      params.expect(warehouse: [ :name, :address, :longitude, :latitude, tag_list: [] ])
    end

    def is_user_authorized
      authorize @warehouse ? @warehouse : Warehouse
    end
end
