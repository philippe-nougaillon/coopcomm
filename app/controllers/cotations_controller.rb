class CotationsController < ApplicationController
  before_action :set_cotation, only: %i[ show edit update destroy pdf ]
  before_action :is_user_authorized, except: :create

  # GET /cotations
  def index
    @cotations = policy_scope(Cotation).kept.includes(:adherent, :service).ordered

    if params[:search].present?
      @cotations = @cotations.where("cotations.ref ILIKE :s OR cotations.intitulé ILIKE :s", s: "%#{params[:search]}%")
    end

    if params[:statut].present?
      @cotations = @cotations.where(statut: params[:statut])
    end

    if params[:adherent_id].present?
      @cotations = @cotations.where(adherent_id: params[:adherent_id])
    end

    @pagy, @cotations = pagy(@cotations, items: 15)
  end

  # GET /cotations/1
  def show
  end

  # GET /cotations/new
  def new
    @cotation = Cotation.new
    @cotation.adherent = find_adherent(params[:adherent_id]) if params[:adherent_id].present?
    @cotation.cotation_lignes.build
    set_form_collections
  end

  # POST /cotations
  def create
    @cotation = Cotation.new(cotation_params)
    authorize @cotation

    if @cotation.save
      redirect_to @cotation, notice: "Cotation créée."
    else
      set_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  # GET /cotations/1/edit
  def edit
    @cotation.cotation_lignes.build if @cotation.cotation_lignes.empty?
    set_form_collections
  end

  # PATCH/PUT /cotations/1
  def update
    if @cotation.update(cotation_params)
      redirect_to @cotation, notice: "Cotation mise à jour.", status: :see_other
    else
      set_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /cotations/1
  def destroy
    @cotation.discard
    redirect_to cotations_path, notice: "Cotation supprimée.", status: :see_other
  end

  # GET /cotations/1/pdf
  def pdf
    pdf = CotationPdf.new
    pdf.devis(@cotation)

    send_data pdf.render,
              filename: @cotation.pdf_filename,
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_cotation
    @cotation = Cotation.find_by(slug: params[:id])
    redirect_to cotations_path, alert: "Cotation introuvable" if @cotation.nil?
  end

  def is_user_authorized
    authorize(@cotation || Cotation)
  end

  def cotation_params
    params.require(:cotation).permit(
      :adherent_id, :service_id, :intitulé, :statut, :mémo, :date_livraison_souhaitée,
      cotation_lignes_attributes: %i[id prestation_id intitulé qté prix_ht _destroy]
    )
  end

  def find_adherent(identifier)
    User.find_by(slug: identifier) || User.find_by(id: identifier)
  end

  # Collections proposées dans le formulaire, scopées selon le rôle.
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
