class AdminController < ApplicationController
  before_action :is_user_authorized
  before_action :set_organisation_user_tags, only: [:create_new_user, :create_new_user_do]

  def audits
    if current_user.manager_or_admin?
      @audits = Audited::Audit.where(user_id: current_user.organisation.users.pluck(:id))
    else
      @audits = Audited::Audit.where(user_id: current_user.id)
    end
    @types  = @audits.pluck(:auditable_type).uniq.sort
    @actions= %w[update create destroy]
    @users = current_user.organisation.users.ordered 

    if params[:search].present?
      @audits = @audits.where("audited_changes ILIKE ?", "%#{params[:search]}%")
    end

    if params[:start_date].present? && params[:end_date].present? 
      @audits = @audits.where("DATE(created_at) BETWEEN (?) AND (?)", params[:start_date], params[:end_date])
    end

    if params[:user_id].present?
      @audits = @audits.where(user_id: params[:user_id])
    end

    if params[:type].present?
      @audits = @audits.where(auditable_type: params[:type])
    end

    if params[:action_name].present?
      @audits = @audits.where(action: params[:action_name])
    end

    @audits = @audits.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @audits = pagy(@audits, items: 10)
  end

  def create_new_user
    @user = User.new
  end

  def create_new_user_do
    @user = User.new(params.require(:user).permit(:nom, :prénom, :téléphone, :email, :password, :rôle, :service, :localisation))
    @user.organisation = current_user.organisation

    respond_to do |format|
      if @user.save
        format.html { redirect_to users_url, notice: "Utilisateur créé avec succès." }
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
    @warehouses = current_user.organisation.warehouses
    @services = current_user.services
    @users = current_user.organisation.users.filter_by_service(@services)

    if params[:search].present?
      @services = @services.where("nom ILIKE :search", {search: "%#{params[:search]}%"})
      @warehouses = @warehouses.where("name ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:user_id].present?
      @services = @services.joins(:users).where(users: {id: params[:user_id]})
    end
  end

  private

  def is_user_authorized
    authorize :admin
  end

  def sortable_columns
    ['audits.created_at', 'audits.user_id', 'audits.auditable_type', 'audits.auditable_id', 'audits.action', 'audits.audited_changes']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : "audits.id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

end
