class CommandesController < ApplicationController
  before_action :set_commande, only: %i[ show edit update destroy pdf envoyer valider refuser ]
  before_action :is_user_authorized
  before_action :set_form_collections, only: %i[edit]

  # GET /commandes or /commandes.json
  def index
    @services = current_user.services
    @adhérents = User.by_service(@services).adhérent

    @commandes = Commande
                        .kept
                        .includes(:adherent, :service, :organisation)
                        .where(service: @services)
                        .ordered

    if params[:search].present?
      @commandes = @commandes.where('commandes.ref ILIKE :s OR commandes.intitulé ILIKE :s', s: "%#{params[:search]}%")
    end

    if params[:adhérent_ids].present?
      @commandes = @commandes.where(adherent_id: params[:adhérent_ids])
    end

    if params[:service_ids].present?
      @commandes = @commandes.where(service_id: params[:service_ids])
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
    @commande.discard
    redirect_to commandes_path, notice: 'Commande supprimée.', status: :see_other
  end

  def pdf
    pdf = CommandePdf.new
    pdf.devis(@commande)
    send_data pdf.render,
              filename: @commande.pdf_filename,
              type: 'application/pdf',
              disposition: 'inline'
  end

  # Transitions du workflow
  def envoyer
    transition!(:envoyer, 'Commande envoyée.') do
      notify_adherent_commande_envoyee
    end
  end

  def valider
    transition!(:valider, 'Commande validée.')
  end

  def refuser
    transition!(:refuser, 'Commande refusée.')
  end

  private

  def transition!(event, notice)
    if @commande.send("can_#{event}?")
      @commande.send("#{event}!")
      # Effet de bord optionnel propre à l'action (ex. notifier l'adhérent pour
      # `envoyer`) : exécuté seulement si un bloc est fourni ET après une
      # transition réussie. Sans bloc (valider/refuser), on ne fait rien.
      yield if block_given?
      redirect_to @commande, notice: notice
    else
      redirect_to @commande, alert: "Action impossible dans l'état actuel de la commande."
    end
  end

  # Notifie l'adhérent (mail + PDF + copie à l'émetteur) que sa commande est
  # envoyée. Sans email côté adhérent, on n'envoie rien.
  def notify_adherent_commande_envoyee
    adherent = @commande.adherent
    return if adherent&.email.blank?

    NotifAdherentCommandeEnvoyeeJob.perform_later(@commande, adherent, current_user.id)
  end

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
