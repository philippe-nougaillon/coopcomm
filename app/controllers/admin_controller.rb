# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :is_user_authorized
  before_action :set_users_tags, only: %i[create_new_user create_new_user_do]

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
    @pagy, @audits = pagy(@audits, items: 6)
  end

  def create_new_user
    @user = User.new
  end

  def create_new_user_do
    @user = User.new(params.require(:user).permit(:nom, :prénom, :téléphone, :email, :password, :rôle, :service,
                                                  :address, :latitude, :longitude))

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
    @warehouses = current_organisation.warehouses
    @services = current_user.services
    @users = User.by_service(@services)
    @prestations = current_organisation.prestations.ordered

    if params[:search].present?
      @services = @services.where('nom ILIKE :search', { search: "%#{params[:search]}%" })
      @warehouses = @warehouses.where('name ILIKE :search', { search: "%#{params[:search]}%" })
      @prestations = @prestations.where('code ILIKE :search OR libellé ILIKE :search OR catégorie ILIKE :search',
                                        { search: "%#{params[:search]}%" })
    end

    return unless params[:user_id].present?

    @services = @services.joins(:users).where(users: { id: params[:user_id] })
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
