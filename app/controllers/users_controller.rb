# frozen_string_literal: true

class UsersController < ApplicationController
  include UserParamsPermis

  before_action :set_user, only: %i[show edit update destroy inviter edit_password update_password]
  # la méthode reactivate a tout de même un authorize
  before_action :is_user_authorized, except: %i[reactivate]
  # Déclaré dans application_controller.rb
  before_action :set_users_tags, only: %i[edit update]

  require 'capture_stdout'

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
        @users = @users.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
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
    @absences = @user.absences.ordered
    
    all_audits = @user.own_and_associated_audits.reorder(id: :desc).to_a

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

    @services = current_user.services
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

    @agents = @agents.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @agents = pagy(@agents, items: 10)
  end

  def import; end

  def import_do
    if params[:upload].present?
      @mdp = +'' # String mutable (le fichier est en frozen_string_literal) : on y concatène les mots de passe générés
      @success_logs = [] # Utilisateurs traités avec succès
      @error_logs   = [] # Utilisateurs en erreur

      # ✅ V2 : capture stdout pour logs détaillés dans la vue
      @stream = capture_stdout do
        # On lit directement le fichier uploadé (Tempfile) : surtout pas de copie
        # dans public/ — elle y serait servie sans authentification (PII).
        file_with_path = params[:upload].tempfile.path

        @importes = @errors = 0
        index = 1

        # IMPORT XLS
        Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet.open file_with_path
        sheet1 = book.worksheet 0

        # ✅ V1 : mapping dynamique des colonnes (robuste aux variations d'en-têtes)
        first_row = sheet1.row(0).map { |cell| cell.to_s.strip.downcase }

        idx_nom       = first_row.index { |h| h.start_with?('nom') }
        idx_prenom    = first_row.index { |h| h.start_with?('prénom') || h.start_with?('prenom') }
        idx_email     = first_row.index { |h| h.start_with?('email') }
        idx_service   = first_row.index { |h| h.start_with?('service') }
        idx_telephone = first_row.index { |h| h.start_with?('téléphone') || h.start_with?('telephone') }
        idx_memo      = first_row.index { |h| h.start_with?('mémo') || h.start_with?('memo') }

        # ✅ V1 : validation structurelle avant d'itérer
        if idx_nom.nil? || idx_prenom.nil? || idx_email.nil? || idx_service.nil?
          flash.now[:alert] =
            'Structure du fichier invalide. Les colonnes obligatoires (Nom, Prénom, Email, Service) sont introuvables.'
          @errors += 1
        else
          sheet1.each 1 do |row|
            index += 1
            next unless row[idx_nom].present?

            email_value = row[idx_email]&.to_s&.strip&.downcase
            next if email_value.blank?

            user = User.where('lower(email) = ?', email_value).first_or_initialize
            new_record = user.new_record?

            user.nom       = row[idx_nom]&.to_s&.strip&.upcase
            user.prénom    = row[idx_prenom]&.to_s&.strip&.humanize
            user.email     = email_value
            user.téléphone = idx_telephone ? row[idx_telephone]&.to_s&.strip : nil
            user.memo      = idx_memo ? row[idx_memo]&.to_s&.strip : nil

            if new_record
              password = User.generate_random_password
              user.password = password
              @mdp << password
            end
            user.rôle = 'agent'

            service_name = row[idx_service]&.to_s&.strip&.humanize
            service = Service.find_by(nom: service_name)

            if service
              already_linked = user.user_services.any? do |us|
                us.service_id == service.id && !us.marked_for_destruction?
              end
              user.user_services.build(service: service) unless already_linked
            end

            user.valid?

            # ✅ Après user.valid? pour ne pas écraser l'erreur
            unless service
              user.errors.add(:services,
                              "introuvable dans la base de données (Valeur lue: '#{service_name || 'VIDE'}')")
            end

            # ✅ V2 : logs détaillés des changements
            safe_changes = user.changes.except('encrypted_password', 'password', 'slug')
            display_changes = new_record ? safe_changes.transform_values(&:last) : safe_changes.dup

            services_changed = user.user_services.any? { |us| us.new_record? || us.marked_for_destruction? }

            if new_record || services_changed
              nouveaux_services = user.user_services.reject(&:marked_for_destruction?).filter_map do |us|
                us.service&.nom
              end.join(', ')
              nouveaux_services = 'Aucun' if nouveaux_services.blank?

              if new_record
                display_changes['service'] = nouveaux_services
              else
                anciens_services = user.user_services.select(&:persisted?).filter_map do |us|
                  us.service&.nom
                end.join(', ')
                anciens_services = 'Aucun' if anciens_services.blank?
                display_changes['service'] = [anciens_services, nouveaux_services]
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
                user.invite!(current_user) if new_record
              end
              @importes += 1
              # ✅ V1 : alimentation des logs succès pour la vue
              @success_logs << {
                type: new_record ? 'Nouveau' : 'Mise à jour',
                email: user.email,
                nom: "#{user.nom} #{user.prénom}",
                service: service&.nom || 'Aucun'
              }
            else
              puts ' || ERREURS: ' + user.errors.messages.map { |m| "#{m.first} => #{m.last}" }.join(', ')
              @errors += 1
              # ✅ V1 : alimentation des logs erreurs pour la vue
              @error_logs << {
                email: email_value,
                nom: "#{row[idx_nom]} #{row[idx_prenom]}",
                service_tente: row[idx_service],
                messages: user.errors.full_messages
              }
            end
          end

          puts
          unless params[:save] == 'true'
            puts "----------- Les modifications n'ont pas été enregistrées ! ---------------"
          end
          puts

          puts '=' * 40
          puts "Lignes importées: #{@importes} | Lignes ignorées: #{@errors}"
          puts '=' * 40

          # ✅ V1 : flash.now correct (pas de redirect, on reste sur la page)
          if @errors.positive?
            flash.now[:alert] = @importes.zero? ? "L'importation a échouée." : "L'importation a partiellement échouée."
          else
            flash.now[:notice] = "L'importation a bien été exécutée."
          end
        end
      end 
    else
      flash[:alert] = "Manque le fichier source pour pouvoir lancer l'importation !"
      redirect_to action: 'import'
    end
  end

  def inviter
    @user.invite!(current_user)
    redirect_to user_path(@user), notice: 'Lien d\'accès renvoyé avec succès.'
  end

  def interventions_average
    interventions.average(:note)&.round(2) || 0
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
    return unless @user.nil?

    redirect_to root_path, alert: 'Utilisateur introuvable'
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def is_user_authorized
    authorize @user || User
  end

  def sortable_columns
    ['users.nom', 'users.rôle', 'users.service', 'users.email', 'users.memo']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'users.nom'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end