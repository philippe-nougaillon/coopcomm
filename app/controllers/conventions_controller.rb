# frozen_string_literal: true

class ConventionsController < ApplicationController
  before_action :set_convention, only: %i[show edit update destroy pdf relancer valider]
  before_action :is_user_authorized
  before_action :exiger_l_ia, only: %i[analyses analyser]

  trie Convention, defaut: 'conventions.date_début', sens: :desc

  # GET /conventions
  def index
    set_index_filter_collections

    @conventions = policy_scope(Convention)
                   .includes(:user, :service, document_attachment: :blob)
                   .with_validé_state
                   .ordered

    # Recherche sur le nom du document attaché, mémo et heures conventionnées 
    if params[:search].present?
      search_term = "%#{params[:search].strip}%"
      @conventions = @conventions.left_joins(document_attachment: :blob)
                                .where(
                                  'conventions.mémo ILIKE :s OR CAST(conventions.heures_conventionnees AS TEXT) ILIKE :s OR active_storage_blobs.filename ILIKE :s',
                                  s: search_term
                                )
    end

    @conventions = @conventions.where(user_id: params[:adherent_id]) if params[:adherent_id].present?

    @conventions = @conventions.where(service_id: params[:service_id]) if params[:service_id].present?

    # Conventions actives à la date choisie (période début → fin prévue, fin ouverte si nulle)
    if params[:active_on].present?
      @conventions = @conventions.where(
        'date_début <= :d AND (date_fin_prévue IS NULL OR date_fin_prévue >= :d)',
        d: params[:active_on]
      )
    end

    @pagy, @conventions = pagy(trier(@conventions), items: 10)
  end

  # GET /conventions/1
  def show
    @audits = trier(@convention.audits.includes(:user))
    @pagy, @audits = pagy(@audits, items: 10)
  end

  # GET /conventions/new
  def new
    @convention = Convention.new(date_début: Date.current.beginning_of_year)
    @convention.user = find_adherent(params[:adherent_id]) if params[:adherent_id].present?
    set_form_collections
  end

  # POST /conventions
  def create
    @convention = Convention.new(convention_params)
    authorize @convention

    if @convention.save
      redirect_to conventions_path, notice: 'Convention enregistrée.'
    else
      set_form_collections
      render :new, status: :unprocessable_content
    end
  end

  # Aciton désactivée
  # GET /conventions/1/edit
  def edit
    set_form_collections
    retirer_ce_que_le_formulaire_ne_propose_pas unless @convention.validé?
  end
  
  # Action désactivée
  # PATCH/PUT /conventions/1
  def update
    if @convention.update(convention_params)
      redirect_to (@convention.validé? ? conventions_path : @convention), notice: 'Convention mise à jour.', status: :see_other
    else
      set_form_collections
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /conventions/1
  def destroy
    @convention.destroy
    redirect_to (@convention.validé? ? conventions_path : analyses_conventions_path), notice: 'Convention supprimée.', status: :see_other
  end

  def pdf
    pdf = TransformToPdf::Convention.call(@convention)

    send_data pdf.render,
              filename: @convention.pdf_filename,
              type: 'application/pdf',
              disposition: 'inline'
  end

  # GET /conventions/services_for_adherent (JSON) — services encore disponibles pour l'adhérent
  # (scopé : l'id d'un adhérent d'une autre organisation ne doit rien révéler)
  def services_for_adherent
    adherent = current_organisation.users.find_by(id: params[:adherent_id])
    render json: available_services_for(adherent).select(:id, :nom)
  end

  # POST /conventions/1/relancer
  def relancer
    if @convention.can_relancer? && InterrogerIa.configuree?
      @convention.relancer!
      AnalyserConventionJob.perform_later(@convention)
      flash[:notice] = 'Analyse relancée.'
    end
    redirect_to analyses_conventions_path, status: :see_other
  end

  # PATCH /conventions/1/valider
  def valider
    return redirect_to @convention, alert: 'Cette convention ne peut pas être validée.', status: :see_other unless @convention.can_valider?

    @convention.valider!
    redirect_to @convention, notice: 'Convention validée.', status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to @convention, alert: "Convention non validée : #{@convention.errors.full_messages.to_sentence}", status: :see_other
  end

  # GET /conventions/analyses
  def analyses
    set_index_filter_collections
    @convention = Convention.new
    @etat_ia = InstanceIa.etat_affiche

    @analyses = policy_scope(Convention).without_validé_state.includes(:user, :service, :deposant, document_attachment: :blob)
    @analyses = @analyses.where(user_id: params[:adherent_id]) if params[:adherent_id].present?

    services = Array(params[:service_id]).compact_blank
    @analyses = @analyses.where(service_id: services) if services.any?

    @analyses = @analyses.where(workflow_state: params[:etat]) if params[:etat].present?

    du = date_param(:du)
    au = date_param(:au)
    @analyses = @analyses.where(created_at: du.beginning_of_day..) if du
    @analyses = @analyses.where(created_at: ..au.end_of_day) if au

    @pagy, @analyses = pagy(trier(@analyses, defaut: 'conventions.updated_at', sens: :desc), items: 10)
  end

  # POST /conventions/analyses
  def analyser
    documents = Array(params.dig(:convention, :document)).compact_blank
    refus = documents.filter_map do |document|
      convention = Convention.new(workflow_state: Convention::EN_ATTENTE, deposant: current_user, document: document)
      "#{document.original_filename} : #{convention.errors.full_messages.to_sentence}" unless convention.save
    end

    if refus.size < documents.size
      flash[:notice] = "#{documents.size - refus.size} document(s) déposé(s), l'analyse démarre. Une notification par mail vous sera envoyée une fois le travail effectué."
    end
    flash[:alert] = 'Aucun document déposé.' if documents.empty?
    flash[:alert] = refus.join(' ; ') if refus.any?
    redirect_to analyses_conventions_path
  end

  private

  def set_convention
    @convention = Convention.find_by(slug: params[:id])
    return unless @convention.nil?

    redirect_to root_path, alert: 'Convention introuvable'
  end

  def is_user_authorized
    authorize(@convention || Convention)
  end

  def convention_params
    params.require(:convention).permit(:user_id, :service_id, :date_début, :date_fin_prévue, :date_signature, :mémo, :résumé, :document, :heures_conventionnees)
  end

  def find_adherent(identifier)
    User.find_by(slug: identifier) || User.find_by(id: identifier)
  end

  # Une valeur absente d'une liste déroulante y serait remplacée en silence par sa première option.
  def retirer_ce_que_le_formulaire_ne_propose_pas
    @convention.user = nil unless @adherents.include?(@convention.user)
    @available_services = available_services_for(@convention.user)
    @convention.service = nil unless @available_services.include?(@convention.service)
  end

  def set_form_collections
    @adherents = if current_user.administrateur?
                   current_organisation.users.adhérent.ordered
                 else
                   User.by_service(current_user.services).adhérent.ordered
                 end
    @available_services = available_services_for(@convention.user)
  end

  # Collections (tous les adhérents / services du périmètre) pour les filtres de l'index
  def set_index_filter_collections
    @services = current_user.get_services_by_role

    @adherents = User.by_service(@services).adhérent.ordered
  end

  # TODO VU : Si ça reste tel quel, il y a peut-être moyen de mettre ça dans le model, voire de fusionner ça avec l'autre fonction "services_for_adherent" utilisé dans les interventions
  # Services de l'adhérent gérables par l'utilisateur courant et sans convention existante
  def available_services_for(adherent)
    return Service.none if adherent.nil?

    current_user.administrateur? ? adherent.services : adherent.services.where(id: current_user.service_ids)
  end

  def exiger_l_ia
    redirect_to conventions_path, alert: "L'analyse par l'IA n'est pas configurée sur cette instance." unless InterrogerIa.configuree?
  end

  def date_param(clé)
    Date.parse(params[clé].to_s) if params[clé].present?
  rescue Date::Error
    nil
  end
end
