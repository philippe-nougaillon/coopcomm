# frozen_string_literal: true

class CotationsController < ApplicationController
  before_action :set_cotation, only: %i[show edit update destroy pdf envoyer valider refuser create_commande]
  before_action :is_user_authorized, except: :create

  # GET /cotations
  def index
    @cotations = policy_scope(Cotation).kept.includes(:adherent, :service).ordered

    if params[:search].present?
      @cotations = @cotations.where('cotations.ref ILIKE :s OR cotations.intitulé ILIKE :s', s: "%#{params[:search]}%")
    end

    if params[:workflow_state].present?
      @cotations = @cotations.where('cotations.workflow_state = ?', params[:workflow_state].to_s.downcase)
    end

    @cotations = @cotations.where(adherent_id: params[:adherent_id]) if params[:adherent_id].present?

    @pagy, @cotations = pagy(@cotations, items: 15)

    # Dernier mail_log par cotation, en une seule requête (DISTINCT ON, Postgres)
    # pour éviter un N+1 dans l'index.
    @last_mail_logs = MailLog
                      .where(cotation_id: @cotations.map(&:id))
                      .select('DISTINCT ON (cotation_id) *')
                      .order(:cotation_id, created_at: :desc)
                      .index_by(&:cotation_id)
  end

  # GET /cotations/1
  def show
    @audits = @cotation.own_and_associated_audits.includes(:user).reorder(id: :desc)
    @pagy, @audits = pagy(@audits, items: 10)
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
      redirect_to @cotation, notice: 'Cotation créée.'
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
      redirect_to @cotation, notice: 'Cotation mise à jour.', status: :see_other
    else
      set_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /cotations/1
  def destroy
    @cotation.discard
    redirect_to cotations_path, notice: 'Cotation supprimée.', status: :see_other
  end

  # GET /cotations/1/pdf
  def pdf
    pdf = CotationPdf.new
    pdf.devis(@cotation)

    send_data pdf.render,
              filename: @cotation.pdf_filename,
              type: 'application/pdf',
              disposition: 'inline'
  end

  # Transitions du workflow
  def envoyer
    transition!(:envoyer, 'Cotation envoyée.') do
      notify_adherent_cotation_envoyee
    end
  end

  def valider
    transition!(:valider, 'Cotation validée.')
  end

  def refuser
    transition!(:refuser, 'Cotation refusée.')
  end

  def create_commande
    if @cotation.present?

      @commande = CreateCommandeFromCotation.new(@cotation).call

      if @commande.save
        redirect_to @commande, notice: "Commande créée avec succès."
      else
        redirect_to @cotation, alert: "Impossible de créer la commande."
      end
    end
  end

  private

  def transition!(event, notice)
    if @cotation.send("can_#{event}?")
      @cotation.send("#{event}!")
      # Effet de bord optionnel propre à l'action (ex. notifier l'adhérent pour
      # `envoyer`) : exécuté seulement si un bloc est fourni ET après une
      # transition réussie. Sans bloc (valider/refuser), on ne fait rien.
      yield if block_given?
      redirect_to @cotation, notice: notice
    else
      redirect_to @cotation, alert: "Action impossible dans l'état actuel de la cotation."
    end
  end

  # Notifie l'adhérent (mail + PDF + copie à l'émetteur) que sa cotation est
  # envoyée. Sans email côté adhérent, on n'envoie rien.
  def notify_adherent_cotation_envoyee
    adherent = @cotation.adherent
    return if adherent&.email.blank?

    NotifAdherentCotationEnvoyeeJob.perform_later(@cotation, adherent, current_user.id)
  end

  def set_cotation
    @cotation = Cotation.find_by(slug: params[:id])
    redirect_to cotations_path, alert: 'Cotation introuvable' if @cotation.nil?
  end

  def is_user_authorized
    authorize(@cotation || Cotation)
  end

  def cotation_params
    params.require(:cotation).permit(
      :adherent_id, :service_id, :intitulé, :mémo, :date_livraison_souhaitée,
      cotation_lignes_attributes: %i[id prestation_id intitulé qté _destroy]
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
