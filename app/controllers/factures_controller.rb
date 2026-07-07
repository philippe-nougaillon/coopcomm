class FacturesController < ApplicationController
  before_action :set_facture, only: %i[ show edit update destroy pdf envoyer valider refuser ]
  before_action :is_user_authorized
  before_action :set_form_collections, only: %i[edit]


  # GET /factures or /factures.json
  def index
    @services = current_user.services
    @adhérents = User.by_service(@services).adhérent

    @factures = Facture
                   .kept
                   .includes(:adherent, :service, :organisation)
                   .where(service: @services)
                   .ordered

    if params[:search].present?
      @factures = @factures.where('factures.ref ILIKE :s OR factures.intitulé ILIKE :s', s: "%#{params[:search]}%")
    end

    if params[:adhérent_ids].present?
      @factures = @factures.where(adherent_id: params[:adhérent_ids])
    end

    if params[:service_ids].present?
      @factures = @factures.where(service_id: params[:service_ids])
    end

    if params[:workflow_state].present?
      @factures = @factures.where('factures.workflow_state = ?', params[:workflow_state].to_s.downcase)
    end

    @factures = @factures.where(adherent_id: params[:adherent_id]) if params[:adherent_id].present?

    @pagy, @factures = pagy(@factures, items: 15)
  end

  # GET /factures/1 or /factures/1.json
  def show
    @audits = @facture.own_and_associated_audits.includes(:user).reorder(id: :desc)
    @pagy, @audits = pagy(@audits, items: 10)
  end

  # GET /factures/new
  # def new
  #   @facture = Facture.new
  # end

  # GET /factures/1/edit
  def edit
  end

  # POST /factures or /factures.json
  # def create
  #   @facture = Facture.new(facture_params)
  #
  #   respond_to do |format|
  #     if @facture.save
  #       format.html { redirect_to @facture, notice: "Facture créée avec succès." }
  #       format.json { render :show, status: :created, location: @facture }
  #     else
  #       format.html { render :new, status: :unprocessable_content }
  #       format.json { render json: @facture.errors, status: :unprocessable_content }
  #     end
  #   end
  # end

  # PATCH/PUT /factures/1 or /factures/1.json
  def update
    respond_to do |format|
      if @facture.update(facture_params)
        format.html { redirect_to @facture, notice: "Facture modifiée avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @facture }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @facture.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /factures/1 or /factures/1.json
  def destroy
    @facture.discard
    redirect_to factures_path, notice: 'Facture supprimée.', status: :see_other
  end

  def pdf
    pdf = TransformToPdf::Facture.call(@facture)

    send_data pdf.render,
              filename: @facture.pdf_filename,
              type: 'application/pdf',
              disposition: 'inline'
  end

  # Transitions du workflow
  def envoyer
    transition!(:envoyer, 'Facture envoyée.') do
      notify_adherent_facture_envoyee
    end
  end

  def valider
    transition!(:valider, 'Facture validée.')
  end

  def refuser
    transition!(:refuser, 'Facture refusée.')
  end

  private

  def transition!(event, notice)
    if @facture.send("can_#{event}?")
      @facture.send("#{event}!")
      # Effet de bord optionnel propre à l'action (ex. notifier l'adhérent pour
      # `envoyer`) : exécuté seulement si un bloc est fourni ET après une
      # transition réussie. Sans bloc (valider/refuser), on ne fait rien.
      yield if block_given?
      redirect_to @facture, notice: notice
    else
      redirect_to @facture, alert: "Action impossible dans l'état actuel de la facture."
    end
  end

  # Notifie l'adhérent (mail + PDF + copie à l'émetteur) que sa facture est
  # envoyée. Sans email côté adhérent, on n'envoie rien.
  def notify_adherent_facture_envoyee
    adherent = @facture.adherent
    return if adherent&.email.blank?

    NotifAdherentFactureEnvoyeeJob.perform_later(@facture, adherent, current_user.id)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_facture
    @facture = Facture.find_by(slug: params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def facture_params
    params.require(:facture).permit(
      :adherent_id, :service_id, :intitulé, :mémo, :date_livraison_souhaitée,
      facture_lignes_attributes: %i[id prestation_id intitulé qté _destroy]
    )
  end

  def is_user_authorized
    authorize(@facture || Facture)
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
