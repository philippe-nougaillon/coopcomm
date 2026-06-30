class CommandesController < ApplicationController
  before_action :set_commande, only: %i[ show edit update destroy pdf ]
  before_action :is_user_authorized
  before_action :set_form_collections, only: %i[edit]

  # GET /commandes or /commandes.json
  def index
    @commandes = Commande.includes(:adherent, :service).ordered

    if params[:search].present?
      @commandes = @commandes.where('commandes.ref ILIKE :s OR commandes.intitulé ILIKE :s', s: "%#{params[:search]}%")
    end

    if params[:workflow_state].present?
      @commandes = @commandes.where('commandes.workflow_state = ?', params[:workflow_state].to_s.downcase)
    end

    @commandes = @commandes.where(adherent_id: params[:adherent_id]) if params[:adherent_id].present?

    @pagy, @commandes = pagy(@commandes, items: 15)
  end

  # GET /commandes/1 or /commandes/1.json
  def show
    @audits = @commande.own_and_associated_audits.includes(:user).reorder(id: :desc)
    @pagy, @audits = pagy(@audits, items: 10)
  end

  # GET /commandes/new
  # def new
  #   @commande = Commande.new
  # end

  # GET /commandes/1/edit
  def edit
  end

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

  # PATCH/PUT /commandes/1 or /commandes/1.json
  def update
    respond_to do |format|
      if @commande.update(commande_params)
        format.html { redirect_to @commande, notice: "Commande modifiée avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @commande }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @commande.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /commandes/1 or /commandes/1.json
  def destroy
    @commande.destroy!

    respond_to do |format|
      format.html { redirect_to commandes_path, notice: "Commande supprimée avec succès.", status: :see_other }
      format.json { head :no_content }
    end
  end

  def pdf
    pdf = CommandePdf.new
    pdf.devis(@commande)
    send_data pdf.render,
              filename: @commande.pdf_filename,
              type: 'application/pdf',
              disposition: 'inline'
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_commande
    @commande = Commande.find_by(slug: params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def commande_params
    params.require(:commande).permit(
      :adherent_id, :service_id, :intitulé, :mémo, :date_livraison_souhaitée,
      commande_lignes_attributes: %i[id prestation_id intitulé qté _destroy]
    )
  end

  def is_user_authorized
    authorize(@commande || Commande)
  end

  def set_form_collections
    @adherents = if current_user.administrateur?
                   current_organisation.users.adhérent.ordered
                 else
                   User.by_service(current_user.services).adhérent.ordered
                 end

    @services = current_user.administrateur? ? current_organisation.services.ordered : current_user.services.ordered

    @prestations = current_organisation.prestations.ordered
  end
end
