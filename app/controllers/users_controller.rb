class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  before_action :is_user_authorized

  # GET /users or /users.json
  def index
    @users = current_user.organisation.users.ordered
    @services = User.services

    if params[:search].present?
      @users = @users.where("nom ILIKE :search OR prénom ILIKE :search OR email ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:rôle].present?
      @users = @users.where(rôle: params[:rôle])
    end

    if params[:service].present?
      @users = @users.where(service: params[:service])
    end

    @pagy, @users = pagy(@users, items: 15)
  end

  # GET /users/1 or /users/1.json
  def show
    @absences = @user.absences.ordered
    @audits = Audited::Audit.where(user_id: @user.id).reorder(id: :desc)
    @pagy, @audits = pagy(@audits, items: 10)
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
    @user.destroy!

    respond_to do |format|
      format.html { redirect_to users_url, notice: "Utilisateur supprimé avec succès." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find_by(slug: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_params
      params.require(:user).permit(:nom, :prénom, :email, :password, :rôle, :service, absences_attributes: [:id, :_destroy, :du, :au, :motif])
    end

    def is_user_authorized
      authorize @user ? @user : User
    end

end
