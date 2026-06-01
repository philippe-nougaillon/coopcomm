class InterventionsController < ApplicationController
  before_action :set_intervention, only: %i[ show edit update destroy terminer valider refuser archiver purge pointer pointage_statut update_location ]
  before_action :is_user_authorized
  before_action :set_form_variables, only: %i[ new edit create update new_intervention_pointage create_intervention_pointage ]
  before_action :store_return_location, only: [:new, :edit]
  before_action :set_users_tags, only: [:index]
  before_action :set_interventions_tags, only: %i[ index new edit create update new_intervention_pointage create_intervention_pointage ]

  # GET /interventions or /interventions.json
  def index
    session[:vue] ||= 'normal'
    params[:vue] ||= session[:vue]

    @services = current_user.services

    # Récupère les interventions à partir des services de l'utilisateur ou dans les params
    @interventions = Intervention.filter_by_service(params[:service].presence || @services)

    @interventions = @interventions.by_role_for(current_user)
    
    if params[:archives].present?
      @interventions = @interventions.where(workflow_state: 'archivé')
    elsif params[:workflow_state].present?
      @interventions = @interventions.where("interventions.workflow_state = ?", params[:workflow_state].to_s.downcase)
    else
      @interventions = @interventions.where.not(workflow_state: 'archivé')
    end

    # Enlever les interventions filles si ce n'est pas un adhérent
    unless current_user.adhérent?
      @interventions = @interventions.where(template_slug: nil)
    end

    if params[:search].present?
      @interventions = @interventions.where("description ILIKE :search OR commentaires ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:du].present?
      if params[:au].present?
        @interventions = @interventions.where("DATE(début) BETWEEN ? AND ?", params[:du], params[:au])
      else
        @interventions = @interventions.where("DATE(début) = ?", params[:du]).or(@interventions.where("DATE(fin) = ?", params[:du]))
      end
    elsif params[:au].present?
      @interventions = @interventions.where("DATE(fin) = ?", params[:au])
    end

    if params[:adherent_id].present?
      @interventions = @interventions.where(adherent_id: params[:adherent_id])
    end

    if params[:equipe].present?
      # On nettoie le tableau pour enlever l'élément vide ("") envoyé par le formulaire
      tags = params[:equipe].reject(&:blank?)
      
      if tags.any?
        adherent_ids = @users_in_same_services.tagged_with(tags, any: true).pluck(:id)

        # Étape B : On filtre directement sur la clé étrangère de l'intervention
        @interventions = @interventions.where(adherent_id: adherent_ids)
      end
    end

    if params[:agent_ids].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {id: params[:agent_ids]})
    end

    if params[:tool_ids].present?
      @interventions = @interventions.joins(:tool_interventions).where(tool_interventions: {tool_id: params[:tool_ids]})
    end

    if params[:tags].present?
      @interventions = @interventions.tagged_with(params[:tags].reject(&:blank?))
      session[:tags] = params[:tags]
    else
      session[:tags] = params[:tags] = []
    end

    if params[:vue] == 'compact'
      @interventions = @interventions.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    end
    
    @interventions = @interventions.distinct

    users_in_same_services = User.by_service(params[:service].presence || @services)

    @adhérents = users_in_same_services.adhérent.order(:nom)

    if current_user.manager_or_admin? || current_user.adhérent?
      @grouped_agents = users_in_same_services.grouped_agents(current_user)
    end

    @tools = current_organisation.tools.ordered

    session[:vue] = params[:vue]

    @interventions = @interventions.includes(:tags, :agents, :adherent, :service, :organisation, :tools).with_attached_photos

    respond_to do |format|
      format.html do
        @pagy, @interventions = pagy(@interventions)
      end

      format.xls do
        xls_file = InterventionsToXls.new(@interventions).call
        send_data xls_file, filename: "Interventions_#{l Date.today}.xls"
      end
    end
  end

  # GET /interventions/1 or /interventions/1.json
  def show
    # TODO : Déplacer le stale au plus près du render
    # if stale?(@intervention)

      if @intervention.repeter?
        if current_user.agent?
          @pointages = current_user.interventions.where(template_slug: @intervention.slug, repeter: false)
        else
          @pointages = @intervention.pointages
        end
        @pointages = @pointages.ordered
      end

      unless Rails.env.test?
        # On vérifie que l'intervention possède un adhérent localisé ET que le service nécessite le calcul
        @localisation_depart = @intervention.origin_location
        if @localisation_depart && @intervention.adherent.present? && @intervention.adherent.latitude.present? && @intervention.adherent.longitude.present? && @intervention.service&.calculate_distance?
          if @intervention.trajet.blank? || @intervention.nouveau?
            
            localisation_arrivee = { lat: @intervention.adherent.latitude, lng: @intervention.adherent.longitude }

            # Création du service avec le départ et la destination
            request = ApiGoogleMaps.new(@localisation_depart, localisation_arrivee)
            request.call

            # Récupération des données via les getters du service
            @localisation_arrivee = localisation_arrivee
            @errors = request.errors
            @routes_info = request.routes_info
            @response = request.data_response
          end
        end
      end

      respond_to do |format|
        format.html do
          @audits = @intervention.own_and_associated_audits.includes(:user).reorder(id: :desc)
          @pagy, @audits = pagy(@audits, items: 10)
        end

        format.pdf do
          authorize @intervention, :can_see_qrcode_pointage_pdf?

          filename = "QRCode_Pointeuse_#{@intervention.description}"
          pdf = InterventionPdf.new
          pdf.pointeuse_qrcode(@intervention)

          send_data pdf.render,
              filename: filename.concat('.pdf'),
              type: 'application/pdf',
              disposition: 'inline'
        end
      end
    # end
  end

  # GET /interventions/new
  def new
    @intervention = Intervention.new

    if current_user.agent?
      @intervention.agent_ids = current_user.id
      
      # Par défaut, un agent saisi une intervention après l'avoir réalisé (le soir)
      @intervention.workflow_state = "terminé"
    else
      # Si on passe par le planning des agents
      @intervention.agent_ids = params[:agent_id]
    end

    # Ajout de la date de fin si c'est un agent et que la date début prévue et fin prévue sont nil
    if current_user.agent? && (params[:début_prévue].blank? || params[:fin_prévue].blank?)
      now = DateTime.now()
      # Le nombre de minute doit être un mutliple de 5, 
      # Pour cela, on enlève le nombre de minutes modulo 5 (Ex: Si on a 14 minutes -> 14%5 = 4, donc 14-4 = 10)
      # date_fin = now - now.minute.modulo(5).minute
      # modulo plus nécessaire, le step(5) a été retiré
      date_fin = now

      @intervention.fin = date_fin
    end
  end

  # GET /interventions/1/edit
  def edit
  end

  # POST /interventions or /interventions.json
  def create
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_organisation
    update_tag_list

    respond_to do |format|
      if @intervention.save
        format.html { redirect_to intervention_url(@intervention), notice: "Intervention créée avec succès." }
        format.json { render :show, status: :created, location: @intervention }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @intervention.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /interventions/1 or /interventions/1.json
  def update
    @intervention.assign_attributes(intervention_params)
    update_tag_list

    respond_to do |format|
      if @intervention.save
        unless Rails.env.development?
          Events.instance.publish('intervention.updated', payload: {intervention_id: @intervention.id})
        end
        format.html do
          # Si c'est une modification du commentaire dans le pointage statut, on redirige vers home
          if params[:commit] == "Enregistrer le commentaire"
            redirect_to root_path, notice: "Commentaire modifiée avec succès."
          else
            redirect_to intervention_url(@intervention), notice: "Intervention modifiée avec succès."
          end
        end
        format.json { render :show, status: :ok, location: @intervention }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @intervention.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /interventions/1 or /interventions/1.json
  def destroy
    respond_to do |format|
      if @intervention.destroy
        format.html { redirect_to interventions_url, notice: "Intervention supprimée avec succès." }
        format.json { head :no_content }
      else
        # Nécessaire s'il y a des erreurs
        flash[:alert] = "L'intervention ne peut pas être supprimée : #{@intervention.errors.full_messages.join(', ')}"
        format.html { redirect_to @intervention, status: :see_other } # see_other = erreur 303 = Redirection après échec de suppression 
      end
    end
  end

  # def accepter
  #   @intervention.accepter!
  #   # send_workflow_changed_notification
  #   redirect_to @intervention, notice: "Intervention acceptée"
  # end

  # def en_cours
  #   @intervention.en_cours!
  #   # send_workflow_changed_notification
  #   redirect_to @intervention, notice: "Intervention en cours"
  # end

  def terminer
    if @intervention.can_terminer?
      @intervention.terminer!
      @intervention.calculate_co2
      send_workflow_changed_notification
      send_intervention_termine_notification
      redirect_to @intervention, notice: "Intervention terminée"
    else
      redirect_to @intervention, notice: "Impossible de terminer l'intervention"
    end

  end

  def valider
    @intervention.valider!
    
    send_workflow_changed_notification

    redirect_to @intervention, notice: "Intervention validée"
  end

  def refuser
    @intervention.refuser!

    send_workflow_changed_notification

    redirect_to @intervention, notice: "Intervention refusée"
  end

  def archiver
    if @intervention.valid?
      if @intervention.can_archiver?
        @intervention.archiver!
        send_workflow_changed_notification
        redirect_to @intervention, notice: "Intervention archivée"
      elsif @intervention.archivé?
        redirect_to @intervention, alert: "L'intervention est déjà archivée"
      else
        redirect_to @intervention, alert: "L'intervention ne peut pas se archiver"
      end
    else
      redirect_to @intervention, alert: "L'intervention n'est pas valide. Elle ne peut pas être archivée"
    end
    # send_workflow_changed_notification
  end

  def purge
    @intervention.photos.find(params[:photo_id]).purge
    @intervention.update(audit_comment: "Photo n°#{params[:photo_id]} supprimée")
    redirect_to @intervention, notice: "Photo supprimée"
  end

  def pointer

    if @intervention.repeter?
      # Intervention fille se passant aujourd'hui (intervention en cours de réalisation)
      current_intervention = Intervention
        .joins(:agent_interventions)
        .where(template_slug: @intervention.slug)
        .where(agent_interventions: { agent_id: current_user.id })
        .where("DATE(début) = ?", Date.today)
        .where(workflow_state: "nouveau") # Seul les nouvelles interventions nous intéresse
        .order(updated_at: :asc) # Trie du plus ancien au plus récent
        .last # Prend l'intervention créée/modifiée la plus récente

      # Si une intervention fille est créé, on la met à jour, sinon on en créée une nouvelle
      if current_intervention.present?
        unless current_intervention.fin
          current_intervention.fin = DateTime.now
          current_intervention.temps_total = current_intervention.calc_temps_total
          current_intervention.workflow_state = "terminé"
          current_intervention.save
          flash[:notice] = "Pointage de fin enregistrée !"
        else
          current_intervention = @intervention.create_next_intervention(@intervention, current_user)
          flash[:notice] = "Reprise d'activité enregistrée !"
        end
      else
        current_intervention = @intervention.create_next_intervention(@intervention, current_user)
        flash[:notice] = "Début de journée enregistrée !"
      end
      unless Rails.env.development?
        Events.instance.publish('intervention.pointage', payload: {intervention_id: current_intervention.id})
      end
      
      redirect_to pointage_statut_intervention_path(current_intervention)
    else
      redirect_to @intervention, alert: "Cette intervention n'est pas un modèle de pointage"
    end
  end

  def pointage_statut
    if @intervention.repeter
      redirect_to pointage_statut_intervention_path(Intervention.find_by(template_slug: @intervention.slug))
    end
  end

  def update_location
    if @intervention.update(localisation: "#{params[:latitude]}, #{params[:longitude]}")
      render json: { status: 'success' }, status: :ok
    else
      render json: { errors: @intervention.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # Récupère les agents en conflit avec les dates passées dans l'URL
  def get_unavailable_elements

    # Récupération des données dans l'url
    intervention_id = params["intervention_id"] != "null" ? params["intervention_id"] : nil
    date_debut_prevue = params["date_debut_prevue"] != "null" ? params["date_debut_prevue"] : nil
    date_fin_prevue = params["date_fin_prevue"] != "null" ? params["date_fin_prevue"] : nil
    
    agent_ids_string = params["agents_ids"] != "null" ? params["agents_ids"] : nil
    # Transforme le string en liste d'agents id
    agent_ids = agent_ids_string.split(',').map(&:to_i) if params["agents_ids"]

    conflicting_agents_ids = []
    conflicting_tool_ids = []

    if agent_ids
      conflicting_agents_ids = Intervention.get_unavailable_agents(intervention_id, agent_ids, date_debut_prevue, date_fin_prevue)
      conflicting_agents_ids += Intervention.get_unavailable_agents_with_absences(agent_ids, date_debut_prevue, date_fin_prevue)
      conflicting_agents_ids.uniq
    end
    
    tool_ids_string = params["tool_ids"] != "null" ? params["tool_ids"] : nil
    # Transforme le string en liste d'agents id
    tool_ids = tool_ids_string.split(',').map(&:to_i) if params["tool_ids"]
    
    if tool_ids
      conflicting_tool_ids = Intervention.get_unavailable_tools(intervention_id, tool_ids, date_debut_prevue, date_fin_prevue)
    end

    json = {
      "agents": conflicting_agents_ids,
      "tools": conflicting_tool_ids
    }

    render json: json, status: :ok
  end

  def services_for_adherent
    adherent = User.find(params[:adherent_id])
    @services = adherent.services.where(id: current_user.service_ids)

    # On renvoie uniquement l'id et le nom pour construire le <select>
    render json: @services.select(:id, :nom)
  end

  # Pour créer une intervention pointage
  def new_intervention_pointage
    @intervention = Intervention.new
    @intervention.repeter = true
  end

  def create_intervention_pointage
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_organisation

    # Force l'intervention à être répété
    @intervention.repeter = true
    @intervention.workflow_state = 'pointage activé'
    
    update_tag_list

    respond_to do |format|
      if @intervention.save
        format.html { redirect_to intervention_url(@intervention), notice: "Modèle de pointage créée avec succès." }
        format.json { render :show, status: :created, location: @intervention }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @intervention.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def get_routage_responses
    
  end
  
  def get_interventions_localisations_to_marker(interventions_par_adherent)
    interventions_par_adherent.map{
      |adherent_id, interventions|
      adherent = User.find(adherent_id)
      { 
        position: adherent.localisation_to_lat_lng_object,
        title: interventions.map {
          |intervention|
          agent_name = intervention.agents.any? ? "#{intervention.agents.first.nom_prénom}, " : ""
          "#{agent_name}#{intervention.description}, #{intervention.début}/#{intervention.fin}"
        }.join(" | "),
        adherent_slug: User.find(adherent_id).slug
      }
    }
  end

  def send_workflow_changed_notification
      unless Rails.env.development? 
        Events.instance.publish('intervention.workflow_changed', payload: {intervention_id: @intervention.id})
      end
    end

    def send_intervention_termine_notification
      unless Rails.env.development?
        Events.instance.publish('intervention.done', payload: {intervention_id: @intervention.id})
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_intervention
      @intervention = Intervention.find_by(slug: params[:id])
      if @intervention.nil?
        redirect_to root_path, alert: "Intervention introuvable"
      end
    end

    def set_form_variables
      @services = current_user.services

      users_in_same_services = User.by_service(@services)

      @adhérents = users_in_same_services.adhérent.order(:nom)

      @grouped_agents = users_in_same_services.grouped_agents(current_user)

      @tools = current_organisation.tools.ordered
    end

    def set_interventions_tags
      @tags = current_organisation.interventions.tag_counts_on(:tags).order(:name)
    end

    # Only allow a list of trusted parameters through.
    def intervention_params
      params.require(:intervention).permit(:adherent_id, :service_id, :début, :début_hour, :début_minute, :fin, :fin_hour, :fin_minute, :temps_de_pause, :temps_total, :description, :commentaires, :workflow_state, :tag_list, :note, :avis, :repeter, :début_prévue, :début_prévue_hour, :début_prévue_minute, :fin_prévue, :fin_prévue_hour, :fin_prévue_minute, :meteo , photos: [], agent_ids: [], tool_ids: [])
    end

    def is_user_authorized
      authorize @intervention ? @intervention : Intervention
    end

    def store_return_location
      session[:return_to] = request.referer if request.referer.present? && URI(request.referer).host == request.host
    end

    def update_tag_list
      if current_user.manager_or_admin?
        @intervention.tag_list = params[:intervention][:tags_manager]
      else
        @intervention.tag_list = params[:intervention][:tags_intervenant]
      end
    end

  def sortable_columns
    ['interventions.description', 'interventions.commentaires', 'interventions.début_prévue', 'interventions.fin_prévue', 'interventions.temps_total', 'interventions.updated_at', 'interventions.workflow_state']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : "interventions.updated_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

end
