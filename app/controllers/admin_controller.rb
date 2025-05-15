class AdminController < ApplicationController
  before_action :is_user_authorized

  def audits
    if current_user.manager?
      @organisation_audits = Audited::Audit.where(user_id: current_user.organisation.users.pluck(:id))
    else
      @organisation_audits = Audited::Audit.where(user_id: current_user.id)
    end
    @audits = @organisation_audits.order("id DESC")
    @types  = @organisation_audits.pluck(:auditable_type).uniq.sort
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

    @pagy, @audits = pagy(@audits, items: 20)
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

  def messagerie
    #@notifications = current_user.notifications

    # Reverse fait dans la vue messagerie pour avoir le dernier en bas, reverse et last transforment en array
    @notifications = Notification.where(from_id: current_user.id).or(Notification.where(to_id: current_user.id)).ordered.limit(9)
    #@new_notification_ids = @notifications.where("notifications.created_at > ?", current_user.notifications_last_seen_at).pluck(:id)

    @users = current_user.organisation.users.where.not(id: current_user.id).ordered
    current_user.update!(notifications_last_seen_at: DateTime.now)
  end

  def send_notification

    if params.has_key? "submit_message"
      notification = Notification.new
      notification.message = params[:message]
      notification.from_id = current_user.id
      notification.to_id = params[:to_id]

      if notification.save
        current_user.update!(notifications_last_seen_at: DateTime.now)
        #render json: { success: true, message: "Notifications envoyées avec succès" }, status: :ok
        redirect_to admin_messagerie_path(to_id: notification.to_id)
      else
        errors = notification.errors.full_messages
        render json: { success: false, errors: errors }, status: :unprocessable_entity
      end
    end    
  end

  def stats
    @organisations = Organisation.all
    # @pagy, @organisations = pagy(@organisations, items: 5)
  end

  private

  def is_user_authorized
    authorize :admin
  end
end
