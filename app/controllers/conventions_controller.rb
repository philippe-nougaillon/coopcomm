# frozen_string_literal: true

class ConventionsController < ApplicationController
  before_action :set_convention, only: %i[show edit update destroy]
  before_action :is_user_authorized, except: :create

  # GET /conventions
  def index
    set_index_filter_collections

    @conventions = policy_scope(Convention)
                   .includes(:user, :service, document_attachment: :blob)
                   .ordered

    # Recherche sur le nom du document attaché
    if params[:search].present?
      @conventions = @conventions.joins(document_attachment: :blob)
                                 .where('active_storage_blobs.filename ILIKE :s', s: "%#{params[:search]}%")
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

    @pagy, @conventions = pagy(@conventions, items: 15)
  end

  # GET /conventions/1
  def show
    @audits = @convention.audits.includes(:user).reorder(id: :desc)
    @pagy, @audits = pagy(@audits, items: 10)
  end

  # GET /conventions/new
  def new
    @convention = Convention.new
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
      render :new, status: :unprocessable_entity
    end
  end

  # GET /conventions/1/edit
  def edit
    set_form_collections
  end

  # PATCH/PUT /conventions/1
  def update
    if @convention.update(convention_params)
      redirect_to conventions_path, notice: 'Convention mise à jour.', status: :see_other
    else
      set_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /conventions/1
  def destroy
    @convention.destroy
    redirect_to conventions_path, notice: 'Convention supprimée.', status: :see_other
  end

  # GET /conventions/services_for_adherent (JSON) — services encore disponibles pour l'adhérent
  # (scopé : l'id d'un adhérent d'une autre organisation ne doit rien révéler)
  def services_for_adherent
    adherent = current_organisation.users.find_by(id: params[:adherent_id])
    render json: available_services_for(adherent).select(:id, :nom)
  end

  private

  def set_convention
    @convention = Convention.find(params[:id])
  end

  def is_user_authorized
    authorize(@convention || Convention)
  end

  def convention_params
    params.require(:convention).permit(:user_id, :service_id, :date_début, :date_fin_prévue, :mémo, :document, :heures_conventionnees)
  end

  def find_adherent(identifier)
    User.find_by(slug: identifier) || User.find_by(id: identifier)
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

    base = current_user.administrateur? ? adherent.services : adherent.services.where(id: current_user.service_ids)
    used = adherent.conventions.where.not(id: @convention&.id).pluck(:service_id)
    base.where.not(id: used).ordered
  end
end
