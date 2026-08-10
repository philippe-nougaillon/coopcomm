# frozen_string_literal: true

class AdminController < ApplicationController
  include UserParamsPermis

  before_action :is_user_authorized
  before_action :set_users_tags, only: %i[create_new_user create_new_user_do]

  trie Service, defaut: 'services.nom'
  trie Warehouse, defaut: 'warehouses.name'
  trie Prestation, defaut: 'prestations.code'

  def audits
    @audits = Audited::Audit.where(user_id: User.by_service(current_user.services).pluck(:id))
    @types = TriTextuel.ranger(@audits.pluck(:auditable_type).uniq)
    @actions = %w[update create destroy]
    @users = User.by_service(current_user.services).ordered

    @audits = @audits.where('audited_changes ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    if params[:start_date].present?
      start_date = Time.zone.parse(params[:start_date])&.beginning_of_day
      @audits = @audits.where('audits.created_at >= ?', start_date) if start_date
    end

    if params[:end_date].present?
      end_date = Time.zone.parse(params[:end_date])&.end_of_day
      @audits = @audits.where('audits.created_at <= ?', end_date) if end_date
    end

    @audits = @audits.where(user_id: params[:user_id]) if params[:user_id].present?

    @audits = @audits.where(auditable_type: params[:type]) if params[:type].present?

    @audits = @audits.where(action: params[:action_name]) if params[:action_name].present?

    @audits = trier(@audits)
    @pagy, @audits = pagy(@audits, items: 10)
  end

  def create_new_user
    @user = User.new(rôle: :agent)
  end

  # `POST /users` est réservé par Devise dès que :registerable est réactivé, d'où
  # cette route dédiée. Les paramètres passent par UserParamsPermis, partagé avec
  # UsersController#update : les deux doivent permettre exactement la même chose.
  def create_new_user_do
    attributs = user_params
    @user = User.new(attributs)
    mot_de_passe = User.generate_random_password

    @user.password = mot_de_passe
    @user.password_confirmation = mot_de_passe

    @user.rôle = 'agent' if current_user.manager?

    # Filet indépendant des validations du modèle : sans service, le compte n'a
    # pas d'organisation, il n'apparaît dans aucune liste et l'invitation échoue.
    sans_service = Array(attributs[:service_ids]).compact_blank.empty?
    @user.errors.add(:services, 'doit comporter au moins un service') if sans_service

    respond_to do |format|
      if !sans_service && @user.save
        @user.invite!(current_user)
        session.delete(:return_to)
        format.html { redirect_to user_url(@user), notice: 'Utilisateur créé avec succès.' }
        format.json { render 'users/show', status: :created, location: @user }
      else
        format.html { render :create_new_user, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  def stats
    @organisations = Organisation.all
  end

  def parametres
  # 1. Definir los Scopes Base
  services_scope = current_organisation.services
  warehouses_scope = current_organisation.warehouses
  prestations_scope = current_organisation.prestations
                                           
  # Lista completa de usuarios para cargar el select del formulario
  @users = User.by_service(current_organisation.services).ordered

  # 2. Aplicar Filtro de Búsqueda por Texto (`:search`)
  if params[:search].present?
    search_term = "%#{params[:search]}%"
    services_scope = services_scope.where('services.nom ILIKE :search', search: search_term)
    warehouses_scope = warehouses_scope.where('warehouses.name ILIKE :search', search: search_term)
    prestations_scope = prestations_scope.where('prestations.code ILIKE :search OR prestations.libellé ILIKE :search OR prestations.catégorie ILIKE :search', search: search_term)
  end

  # 3. Aplicar Filtro por Selección de Usuarios (`:user_id`)
  if params[:user_id].present?
    # Filtrar Servicios por usuarios (INNER JOIN estricto)
    services_scope = services_scope.joins(:users).where(users: { id: params[:user_id] }).distinct
    
    # Filtramos también los Sitios por los usuarios seleccionados
    warehouses_scope = warehouses_scope.joins(:users).where(users: { id: params[:user_id] }).distinct
    
    # Si las prestaciones no tienen usuarios vinculados, las limpiamos cuando filtramos por usuario
    prestations_scope = prestations_scope.none 
  end

  # 4. Conteos Totales Reales para los contadores de los Tabs (Antes de paginar)
  @services_count = services_scope.size
  @warehouses_count = warehouses_scope.size
  @prestations_count = prestations_scope.size

  # 5. Segmentar Consultas y Paginar Exclusivamente el Tab Activo
  case params[:tab]
  when 'sites'
    @pagy, @warehouses = pagy(trier(warehouses_scope))
    @services = []
    @prestations = []
  when 'prestations'
    @pagy, @prestations = pagy(trier(prestations_scope))
    @services = []
    @warehouses = []
  else # 'services' por defecto
    @pagy, @services = pagy(trier(services_scope))
    @warehouses = []
    @prestations = []
  end
end

  private

  def is_user_authorized
    authorize :admin
  end

end