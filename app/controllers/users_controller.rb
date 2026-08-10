# frozen_string_literal: true

class UsersController < ApplicationController
  include UserParamsPermis

  before_action :set_user, only: %i[show edit update destroy inviter edit_password update_password]
  # la méthode reactivate a tout de même un authorize
  before_action :is_user_authorized, except: %i[reactivate]
  # Déclaré dans application_controller.rb
  before_action :set_users_tags, only: %i[edit update]

  trie User, defaut: 'users.nom'
  trie Absence, defaut: 'absences.du', sens: :desc

  # GET /users or /users.json
  def index
    # Périmètre de services filtré (menu + pré-filtre admin), cf. ApplicationController.
    @users = User.by_service(scoped_services(:services))

    @users = @users.unscoped.discarded if params[:discarded].present?
    @users = @users.ordered

    if params[:search].present?
      @users = @users.where('users.nom ILIKE :search OR users.prénom ILIKE :search', { search: "%#{params[:search]}%" })
    end

    @users = @users.where(rôle: params[:rôle]) if params[:rôle].present?

    # ✅ V1 : filtrage par tag
    @users = @users.tagged_with(params[:user_tag]) if params[:user_tag].present?

    if params[:absent].present?
      user_ids = []
      @users.each do |user|
        user_ids << user.id if user.absent?
      end
      @users = @users.where(id: user_ids)
    end

    # ✅ V2 : optimisation N+1
    @users = @users.includes(:taggings).with_attached_profile_picture

    respond_to do |format|
      format.html do
        @users = trier(@users)
        @pagy, @users = pagy(@users, items: 10)
      end

      format.xls do
        xls_file = ExportToXls::Agents.call(@users.agent)
        send_data xls_file, filename: "Agents_#{l Date.today}.xls"
      end
    end
  end

  # GET /users/1 or /users/1.json
  def show
    # TODO : Stale à mettre au plus proche du render
    # if stale?(@user)
    @absences = trier(@user.absences)

    all_audits = trier(@user.own_and_associated_audits).to_a

    filtered_audits = all_audits.reject do |audit|
      if audit.auditable_type == 'User'
        changes = audit.audited_changes
        
        is_only_cookie = changes.keys == ['remember_created_at'] && changes['remember_created_at']&.first.nil?

        is_technical_cleanup = changes.key?('discarded_at') && changes.key?('remember_created_at') && changes['remember_created_at']&.last.nil?

        is_only_cookie || is_technical_cleanup
      else
        false
      end
    end

    page_number = [params[:page].to_i, 1].max
    items_per_page = 10
    
    @audits = filtered_audits.slice((page_number - 1) * items_per_page, items_per_page) || []
    
    @pagy = Pagy.new(count: filtered_audits.size, page: page_number, items: items_per_page)
  end

  # GET /users/1/edit
  def edit; end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    enregistré = false

    # service_ids= écrit les user_services dès l'assignation : sans transaction,
    # un refus de validation les laisserait en base.
    ActiveRecord::Base.transaction do
      @user.assign_attributes(user_params)

      enregistré = @user.save
      raise ActiveRecord::Rollback unless enregistré
    end

    respond_to do |format|
      if enregistré
        bypass_sign_in(@user) if @user == current_user
        format.html { redirect_to user_url(@user), notice: 'Utilisateur modifié avec succès.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit, status: :unprocessable_content }

        # Seule la modale d'absence est réaffichée par turbo-stream : le format
        # n'est déclaré que pour elle, sinon la négociation le préférerait au HTML
        # pour le formulaire principal. Un turbo-stream n'émet ni turbo:load ni
        # turbo:render, donc les slim-select réinjectés n'y sont pas recâblés.
        if params[:from_absence_modal]
          format.turbo_stream do
            absence_en_erreur = @user.absences.to_a.find(&:new_record?) || @user.absences.last
            render turbo_stream: turbo_stream.replace(
              'absence_form',
              partial: 'absence_form',
              locals: {
                user: @user,
                absence: absence_en_erreur
              }
            )
          end
        end

        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.discard

    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Utilisateur supprimé avec succès.' }
      format.json { head :no_content }
    end
  end

  def agent_calendrier
    params[:vue] ||= 'calendrier'
    params[:date] = Date.today if params[:date].blank?
    
    fecha_base = params[:date].to_date
    @date = fecha_base.beginning_of_week 
    @date_fin = fecha_base.end_of_week   

    @services = current_user.services.ordered
    @agents = User.by_service(params[:service].presence || @services).agent
    
    if params[:search].present?
      @agents = @agents.where('users.nom ILIKE :search OR users.prénom ILIKE :search OR users.email ILIKE :search',
                              { search: "%#{params[:search]}%" })
    end

    # Le code actuel n'est pas utile. Si besoin on peut le faire sur la période (@date..@date_fin). Le mieux serait p-e de faire des cases grises directement dans le calendrier.
    # if params[:absent].present?
    #   agent_ids = []
    #   @agents.each do |agent|
    #     agent_ids << agent.id if agent.absences.any?
    #   end
    #   @agents = @agents.where(id: agent_ids)
    # end

    @date_fin = @date + 6.day

    # ✅ V2 : optimisation N+1
    @agents = @agents.with_attached_profile_picture

    @agents = trier(@agents)
    @pagy, @agents = pagy(@agents, items: 10)
  end

  def import; end

  def import_do
    if params[:upload].blank?
      flash[:alert] = 'Manque le fichier source pour pouvoir lancer l\'importation !'
      return redirect_to action: 'import'
    end

    @rapport = ImportUtilisateursXls.call(fichier: params[:upload],
                                          importateur: current_user,
                                          organisation: current_organisation,
                                          appliquer: params[:save] == 'true')

    if @rapport.interrompu?
      flash.now[:alert] = @rapport.message_interruption
    elsif @rapport.en_erreur.positive?
      flash.now[:alert] = @rapport.importés.zero? ? 'L\'importation a échouée.' : 'L\'importation a partiellement échouée.'
    else
      flash.now[:notice] = 'L\'importation a bien été exécutée.'
    end
  end

  def inviter
    @user.invite!(current_user)
    redirect_to user_path(@user), notice: 'Lien d\'accès renvoyé avec succès.'
  end

  def edit_password; end

  def update_password
    respond_to do |format|
      if @user.update(password_params)
        bypass_sign_in(@user) if @user == current_user
        format.html { redirect_to user_url(@user), notice: 'Mot de passe modifié avec succès.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit_password, status: :unprocessable_content }
        format.json { render json: @user.errors, status: :unprocessable_content }
      end
    end
  end

  def reactivate
    @user = User.unscoped.find_by(slug: params[:id])
    authorize @user

    if @user.undiscard
      redirect_to users_path, notice: "Le compte de #{@user.nom_prénom} a été réactivé avec succès."
    else
      redirect_to users_path(discarded: true), alert: 'Impossible de réactiver ce compte.'
    end
  end

  private

  def set_user
    @user = User.find_by(slug: params[:id])
    
    if @user.nil?
      redirect_to root_path, alert: 'Utilisateur introuvable'
    end
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def is_user_authorized
    authorize @user || User
  end

end