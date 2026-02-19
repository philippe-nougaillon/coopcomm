class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :is_user_authorized

  # GET /users or /users.json
  def index
    @services = User.services.sort
    @users = current_user.organisation.users.ordered

    if params[:search].present?
      @users = @users.where("nom ILIKE :search OR prénom ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:rôle].present?
      @users = @users.where(rôle: params[:rôle])
    end

    if params[:service].present?
      @users = @users.where(service: params[:service])
    end

    if params[:absent].present?
      user_ids = []
      @users.each do |user|
        user_ids << user.id if user.absent?
      end
      @users = @users.where(id: user_ids)
    end

    respond_to do |format|
      format.html do
        @users = @users.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
        @pagy, @users = pagy(@users, items: 10)
      end

      format.xls do
        xls_file = AgentsToXls.new(@users.agent).call
        send_data xls_file, filename: "Agents_#{DateTime.now}.xls"
      end
    end
  end

  # GET /users/1 or /users/1.json
  def show
    # TODO : Stale à mettre au plus proche du render
    # if stale?(@user)
      @absences = @user.absences.ordered
      @audits = @user.own_and_associated_audits.reorder(id: :desc)
      if @user.localisation
        @lng = @user.localisation.split(',').last
        @lat = @user.localisation.split(',').first
      end
      @pagy, @audits = pagy(@audits, items: 10)
    # end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    @user.organisation = current_user.organisation

    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user), notice: "Utilisateur créé avec succès." }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        bypass_sign_in(@user) if @user == current_user
        format.html { redirect_to user_url(@user), notice: "Utilisateur modifié avec succès." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.discard

    respond_to do |format|
      format.html { redirect_to users_url, notice: "Utilisateur supprimé avec succès." }
      format.json { head :no_content }
    end
  end

  def agent_calendrier
    params[:vue] ||= 'calendrier'
    params[:date] = Date.today if params[:date].blank?
    @date = params[:date].to_date
    @agents = current_user.organisation.users.where(rôle: "agent")
    @services = User.services.sort

    if params[:search].present?
      @agents = @agents.where("nom ILIKE :search OR prénom ILIKE :search OR email ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:service].present?
      @agents = @agents.where(service: params[:service])
    end

    # Le code actuel n'est pas utile. Si besoin on peut le faire sur la période (@date..@date_fin). Le mieux serait p-e de faire des cases grises directement dans le calendrier.
    # if params[:absent].present?
    #   agent_ids = []
    #   @agents.each do |agent|
    #     agent_ids << agent.id if agent.absences.any?
    #   end
    #   @agents = @agents.where(id: agent_ids)
    # end

    @date_fin = @date + 10.day

    @agents = @agents.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @agents = pagy(@agents, items: 10)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by(slug: params[:id])
      if @user.nil?
        redirect_to root_path, alert: "Utilisateur introuvable"
      end
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:nom, :prénom, :téléphone, :email, :password, :rôle, :service, :memo, :localisation, :profile_picture, :color, absences_attributes: [:id, :_destroy, :du, :au, :motif])
    end

    def is_user_authorized
      authorize @user ? @user : User
    end

    def sortable_columns
      ['users.nom', 'users.rôle', 'users.service', 'users.email', 'users.localisation', 'users.memo']
    end

    def sort_column
      sortable_columns.include?(params[:column]) ? params[:column] : "users.nom"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

end
