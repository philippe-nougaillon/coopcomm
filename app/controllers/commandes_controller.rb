class CommandesController < ApplicationController
  before_action :set_commande, only: %i[ show destroy ]
  before_action :is_user_authorized

  # GET /commandes or /commandes.json
  def index
    @commandes = Commande.all
  end

  # GET /commandes/1 or /commandes/1.json
  def show
  end

  # GET /commandes/new
  # def new
  #   @commande = Commande.new
  # end

  # GET /commandes/1/edit
  # def edit
  # end

  # POST /commandes or /commandes.json
  # def create
  #   @commande = Commande.new(commande_params)
  #
  #   respond_to do |format|
  #     if @commande.save
  #       format.html { redirect_to @commande, notice: "Commande créée avec succès." }
  #       format.json { render :show, status: :created, location: @commande }
  #     else
  #       format.html { render :new, status: :unprocessable_content }
  #       format.json { render json: @commande.errors, status: :unprocessable_content }
  #     end
  #   end
  # end

  # POST /commandes or /commandes.json
  def create_from_cotation
    if cotation = Cotation.find_by(slug: params[:cotation_id])
      # Création de la commande à partir de la cotation
      @commande = Commande.new
      @commande.adherent_id = cotation.adherent_id
      @commande.service_id = cotation.service_id
      @commande.intitulé = cotation.intitulé
      @commande.mémo = cotation.mémo
      @commande.date_livraison_souhaitée = cotation.date_livraison_souhaitée

      if @commande.save
        redirect_to @commande, notice: "Commande créée avec succès."
      else
        redirect_to cotation, alert: "Impossible de créer la commande."
      end
    else
      redirect_to cotations_path, alert: "La cotation n'existe pas."
    end

  end

  # PATCH/PUT /commandes/1 or /commandes/1.json
  # def update
  #   respond_to do |format|
  #     if @commande.update(commande_params)
  #       format.html { redirect_to @commande, notice: "Commande modifiée avec succès.", status: :see_other }
  #       format.json { render :show, status: :ok, location: @commande }
  #     else
  #       format.html { render :edit, status: :unprocessable_content }
  #       format.json { render json: @commande.errors, status: :unprocessable_content }
  #     end
  #   end
  # end

  # DELETE /commandes/1 or /commandes/1.json
  def destroy
    @commande.destroy!

    respond_to do |format|
      format.html { redirect_to commandes_path, notice: "Commande supprimée avec succès.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_commande
      @commande = Commande.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def commande_params
      params.fetch(:commande, {})
    end

    def is_user_authorized
      authorize(@commande || Commande)
    end
end
