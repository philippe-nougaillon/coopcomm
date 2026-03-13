class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy inviter edit_password update_password ]
  # la méthode reactivate a tout de même un authorize
  before_action :is_user_authorized, except: %i[ reactivate ] 
  before_action :set_organisation_user_tags, only: [:new, :create, :edit, :update]

  require 'capture_stdout'

  # GET /users or /users.json
  def index
    @services = current_user.services
    @users = params[:discarded].present? ? current_user.organisation.users.unscoped.discarded : current_user.organisation.users
    @users = @users.filter_by_service(params[:services].presence || @services).ordered

    if params[:search].present?
      @users = @users.where("users.nom ILIKE :search OR users.prénom ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:rôle].present?
      @users = @users.where(rôle: params[:rôle])
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
        send_data xls_file, filename: "Agents_#{l Date.today}.xls"
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
    @user.password = User.generate_random_password

    respond_to do |format|
      if @user.save
        @user.invite!(current_user)
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
        
        format.turbo_stream do
          if params[:from_absence_modal]
            absence_en_erreur = @user.absences.to_a.find(&:new_record?) || @user.absences.last
            render turbo_stream: turbo_stream.replace(
              "absence_form", 
              partial: "absence_form", 
              locals: { 
                user: @user,
                absence: absence_en_erreur 
              }
            )
          else
            render turbo_stream: turbo_stream.replace(
              @user,
              partial: "users/form", # J'ai mis 'users/form' par précaution, adapte si besoin
              locals: { user: @user }
            )
          end
        end
        
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
    @services = current_user.services
    @agents = current_user.organisation.users.filter_by_service(params[:service].presence || @services).where(rôle: "agent")

    if params[:search].present?
      @agents = @agents.where("nom ILIKE :search OR prénom ILIKE :search OR email ILIKE :search", {search: "%#{params[:search]}%"})
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

  def import
  end

  def import_do
    if params[:upload].present?
      @mdp = ""
      @stream = capture_stdout do
        # Enregistre le fichier localement (format = Date + nom du fichier)
        filename = I18n.l(Time.now, format: :long) + ' - ' + params[:upload].original_filename

        file_with_path = Rails.root.join('public', filename)
        File.open(file_with_path, 'wb') do |file|
          file.write(params[:upload].read)
        end

        @importes = @errors = 0 
        index = 1

        # IMPORT XLS
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet.open file_with_path
        sheet1 = book.worksheet 0
        headers = User.xls_headers

        sheet1.each 1 do |row|
          index += 1
          next unless row[0]

          user = User
                    .where("lower(email) = ?", 
                      row[headers.index 'Email']&.strip&.downcase, 
                    )
                    .first_or_initialize

                    
                    new_record = user.new_record?
                    
          user.organisation_id = current_user.organisation_id
          user.nom = row[headers.index 'Nom']&.strip&.upcase
          user.prénom = row[headers.index 'Prénom']&.strip&.humanize
          user.email = row[headers.index 'Email']
          user.téléphone = row[headers.index 'Téléphone']
          if new_record
            password = User.generate_random_password
            user.password = password 
            @mdp << password
          end
          user.rôle = "agent"
          service = Service.find_by(nom: row[headers.index 'Service']&.humanize)

          if service
            already_linked = user.user_services.any? { |us| us.service_id == service.id && !us.marked_for_destruction? }
            unless already_linked
              user.user_services.build(service: service)
            end
          end

          user.memo = row[headers.index 'Mémo']

          user.valid?

          # À faire après user.valid?, sinon l'erreur sera supprimé
          unless service
            user.errors.add(:services, "introuvable dans la base de données")
          end

          safe_changes = user.changes.except("encrypted_password", "password", "slug", "organisation_id")
          display_changes = new_record ? safe_changes.transform_values(&:last) : safe_changes.dup

          # On détecte si les services ont changé en mémoire
          # (S'il y a une nouvelle relation non sauvegardée, ou une relation marquée pour destruction)
          services_changed = user.user_services.any? { |us| us.new_record? || us.marked_for_destruction? }

          # On n'ajoute la clé "services" que s'il y a eu un changement ou si c'est un nouvel utilisateur
          if new_record || services_changed
            nouveaux_services = user.user_services.reject(&:marked_for_destruction?).filter_map { |us| us.service&.nom }.join(', ')
            nouveaux_services = "Aucun" if nouveaux_services.blank?

            if new_record
              display_changes["service"] = nouveaux_services
            else
              # Si c'est une MAJ, on récupère l'ancien état pour imiter le format [Avant, Après] de Rails
              anciens_services = user.user_services.select(&:persisted?).filter_map { |us| us.service&.nom }.join(', ')
              anciens_services = "Aucun" if anciens_services.blank?
              
              display_changes["service"] = [anciens_services, nouveaux_services]
            end
          end

          formatted_changes = display_changes.symbolize_keys

          if formatted_changes.any?
            puts "#{new_record ? 'NOUVEL' : 'MISE À JOUR'} UTILISATEUR => id: #{user.id || 'N/A'}, changes: #{formatted_changes.inspect}"
          else
            puts "UTILISATEUR INCHANGÉ => id: #{user.id}"
          end

          if user.errors.empty? 
            if params[:save] == 'true'
              user.save 
              
              if new_record
                user.invite!(current_user)
              end
            end
            @importes += 1
          else
            puts " || ERREURS: " + user.errors.messages.map { |m| "#{m.first} => #{m.last}" }.join(', ')
            @errors += 1
          end
        end

        puts 
        puts "----------- Les modifications n'ont pas été enregistrées ! ---------------" unless params[:save] == 'true'
        puts

        puts "=" * 40
        puts "Lignes importées: #{@importes} | Lignes ignorées: #{@errors}"
        puts "=" * 40

        if @errors > 0
          flash[:alert] = @importes == 0 ? "L'importation a échouée" : "L'importation a partiellement échouée"
        else
          flash[:notice] = "L'importation a bien été exécutée"
        end
      end
    else
      flash[:alert] = "Manque le fichier source pour pouvoir lancer l'importation !"
      redirect_to action: 'import'
    end 
  end

  def inviter
    @user.invite!(current_user)
    redirect_to user_path(@user), notice: "Utilisateur invité"
  end

  def edit_password
  end

  def update_password
    respond_to do |format|
      if @user.update(user_params)
        bypass_sign_in(@user) if @user == current_user
        format.html { redirect_to user_url(@user), notice: "Mot de passe modifié avec succès." }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit_password, status: :unprocessable_entity }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def reactivate
    @user = User.unscoped.find_by(slug: params[:id])
    authorize @user

    if @user.undiscard
      redirect_to users_path, notice: "Le compte de #{@user.nom_prénom} a été réactivé avec succès."
    else
      redirect_to users_path(discarded: true), alert: "Impossible de réactiver ce compte."
    end
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
      params.require(:user).permit(:nom, :prénom, :téléphone, :email, :password, :password_confirmation, :rôle, :memo, :localisation, :profile_picture, :color, tag_list: [], absences_attributes: [:id, :du, :au, :motif, :observation, :matin, :après_midi, :_destroy], service_ids: [])
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
