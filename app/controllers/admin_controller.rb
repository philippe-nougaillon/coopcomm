# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :is_user_authorized
  before_action :set_users_tags, only: %i[create_new_user create_new_user_do]
  before_action :return_security, only: [:create_new_user]

  def audits
    @audits = if current_user.manager_or_admin?
                Audited::Audit.where(user_id: User.by_service(current_user.services).pluck(:id))
              else
                Audited::Audit.where(user_id: current_user.id)
              end
    @types = @audits.pluck(:auditable_type).uniq.sort
    @actions = %w[update create destroy]
    @users = User.by_service(current_user.services).ordered

    @audits = @audits.where('audited_changes ILIKE ?', "%#{params[:search]}%") if params[:search].present?

    if params[:start_date].present? && params[:end_date].present?
      @audits = @audits.where('DATE(created_at) BETWEEN (?) AND (?)', params[:start_date], params[:end_date])
    end

    @audits = @audits.where(user_id: params[:user_id]) if params[:user_id].present?

    @audits = @audits.where(auditable_type: params[:type]) if params[:type].present?

    @audits = @audits.where(action: params[:action_name]) if params[:action_name].present?

    @audits = @audits.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @audits = pagy(@audits, items: 10)
  end

  def create_new_user
    @user = User.new
  end

  def create_new_user_do
    @user = User.new(params.require(:user).permit(:nom, :prénom, :téléphone, :email, :password, :service,
                                                  :address, :latitude, :longitude))

    # Un manager ne peut créer que des rôles non privilégiés ; seul un
    # administrateur peut attribuer manager/administrateur (anti-escalade).
    rôle = params[:user][:rôle].to_s
    rôles_attribuables = current_user.administrateur? ? User.rôles.keys : %w[adhérent agent]
    @user.rôle = rôle if rôles_attribuables.include?(rôle)

    respond_to do |format|
      if @user.save
        format.html { redirect_to users_url, notice: 'Utilisateur créé avec succès.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :create_new_user, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def stats
    @organisations = Organisation.all
    # @pagy, @organisations = pagy(@organisations, items: 5)
  end

  def parametres
  # 1. Definir los Scopes Base
  services_scope = current_user.services
  warehouses_scope = current_organisation.warehouses
  prestations_scope = current_organisation.prestations.ordered
  
  # Lista completa de usuarios para cargar el select del formulario
  @users = User.by_service(services_scope)

  # 2. Aplicar Filtro de Búsqueda por Texto (`:search`)
  if params[:search].present?
    search_term = "%#{params[:search]}%"
    services_scope = services_scope.where('nom ILIKE :search', search: search_term)
    warehouses_scope = warehouses_scope.where('name ILIKE :search', search: search_term)
    prestations_scope = prestations_scope.where('code ILIKE :search OR libellé ILIKE :search OR catégorie ILIKE :search', search: search_term)
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
    @pagy, @warehouses = pagy(warehouses_scope)
    @services = []
    @prestations = []
  when 'prestations'
    @pagy, @prestations = pagy(prestations_scope)
    @services = []
    @warehouses = []
  else # 'services' por defecto
    @pagy, @services = pagy(services_scope)
    @warehouses = []
    @prestations = []
  end
end

  private

  def is_user_authorized
    authorize :admin
  end

  def sortable_columns
    ['audits.created_at', 'audits.user_id', 'audits.auditable_type', 'audits.auditable_id', 'audits.action',
     'audits.audited_changes']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'audits.id'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
