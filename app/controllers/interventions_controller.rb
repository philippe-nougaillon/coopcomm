class InterventionsController < ApplicationController
  before_action :set_intervention, only: %i[ show edit update destroy terminer valider refuser archiver purge pointer pointage_statut ]
  before_action :set_form_variables, only: %i[ new edit create update ]
  before_action :is_user_authorized, except: %i[ pointer pointage_statut ]
  before_action :store_return_location, only: [:new, :edit]
  skip_before_action :authenticate_user!, only: %i[ pointer pointage_statut ]

  # GET /interventions or /interventions.json
  def index
    @interventions = Intervention.by_role_for(current_user)
    if params[:archives].present?
      @interventions = @interventions.where(workflow_state: 'archivé')
    elsif params[:workflow_state].present?
      @interventions = @interventions.where("interventions.workflow_state = ?", params[:workflow_state].to_s.downcase)
    else
      @interventions = @interventions.where.not(workflow_state: 'archivé')
    end

    organisation_members = current_user.organisation.users
    if current_user.manager?
      @adhérents = organisation_members.adhérent.order(:nom)
      @services = User.services.sort
      @teams = organisation_members.équipe
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.adhérent?
      @adhérents = organisation_members.adhérent.order(:nom)
      @services = User.services
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.équipe?
      @services = User.services
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.agent?
      @adhérents = organisation_members.adhérent.order(:nom)
    end
    @tools = current_user.organisation.tools.ordered
    @tags = @interventions.tag_counts_on(:tags).order(tags_count: :desc).order(:name)

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

    if params[:team_id].present?
      @interventions = @interventions.where(team_id: params[:team_id])
    end

    if params[:service].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {service: params[:service]})
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

    respond_to do |format|
      format.html do
        @pagy, @interventions = pagy(@interventions.includes(:tags, :team, :agents, :adherent).with_attached_photos)
      end

      format.xls do
        xls_file = InterventionsToXls.new(@interventions).call
        send_data xls_file, filename: "Interventions_#{DateTime.now}.xls"
      end
    end
  end

  # GET /interventions/1 or /interventions/1.json
  def show
    respond_to do |format|
      format.html do
        @audits = @intervention.audits.includes(:user).reorder(id: :desc)
        @pagy, @audits = pagy(@audits, items: 10)
      end

      format.pdf do
        filename = "QRCode_Pointeuse_#{@intervention.description}"
        pdf = InterventionPdf.new
        pdf.pointeuse_qrcode(@intervention)

        send_data pdf.render,
            filename: filename.concat('.pdf'),
            type: 'application/pdf',
            disposition: 'inline'
      end
    end
  end

  # GET /interventions/new
  def new
    @intervention = Intervention.new
    @intervention.adherent_id = current_user.id if current_user.adhérent?
    @intervention.agent_ids = current_user.agent? ? current_user.id : params[:agent_ids]
  end

  # GET /interventions/1/edit
  def edit
  end

  # POST /interventions or /interventions.json
  def create
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_user.organisation
    update_tag_list

    if current_user.équipe?
      @intervention.team_id = current_user.id
    end

    check_workflow_pointage_mère

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
    check_workflow_pointage_mère

    respond_to do |format|
      if @intervention.save
        unless Rails.env.development?
          Events.instance.publish('intervention.updated', payload: {intervention_id: @intervention.id})
        end
        format.html { redirect_to intervention_url(@intervention), notice: "Intervention modifiée avec succès." }
        format.json { render :show, status: :ok, location: @intervention }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @intervention.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /interventions/1 or /interventions/1.json
  def destroy
    @intervention.destroy!

    respond_to do |format|
      format.html { redirect_to interventions_url, notice: "Intervention supprimée avec succès." }
      format.json { head :no_content }
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
    if @intervention.valid?
      if @intervention.can_terminer?
        @intervention.terminer!
        send_workflow_changed_notification
        send_intervention_termine_notification
        redirect_to @intervention, notice: "Intervention terminée"
      elsif @intervention.terminé?
        redirect_to @intervention, alert: "L'intervention est déjà terminée"
      else
        redirect_to @intervention, alert: "L'intervention ne peut pas se terminer"
      end
    else
      redirect_to @intervention, alert: "L'intervention n'est pas valide. Elle ne peut pas être terminée"
    end
  end

  def valider
    if @intervention.valid?
      if @intervention.can_valider?
        @intervention.valider!
        send_workflow_changed_notification
        if current_user.adhérent?
          terminé = true
        end
        redirect_to edit_intervention_path(@intervention, terminé: terminé), notice: "Intervention validée"
      elsif @intervention.validé?
        redirect_to @intervention, alert: "L'intervention est déjà validée"
      else
        redirect_to @intervention, alert: "L'intervention ne peut pas se valider"
      end
    else
      redirect_to @intervention, alert: "L'intervention n'est pas valide. Elle ne peut pas être validée"
    end

    # send_workflow_changed_notification
    
  end

  def refuser
    if @intervention.valid?
      if @intervention.can_refuser?
        @intervention.refuser!
        send_workflow_changed_notification
        if current_user.adhérent?
          terminé = true
        end
        redirect_to edit_intervention_path(@intervention, terminé: terminé), notice: "Intervention refusée"
      elsif @intervention.refusé?
        redirect_to @intervention, alert: "L'intervention est déjà refusée"
      else
        redirect_to @intervention, alert: "L'intervention ne peut pas se refuser"
      end
    else
      redirect_to @intervention, alert: "L'intervention n'est pas valide. Elle ne peut pas être refusée"
    end
    # send_workflow_changed_notification
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
    # Prendre l'intervention la plus récente

    if @intervention.repeter?
      current_intervention = Intervention.where(template_slug: @intervention.slug).find_by("DATE(début) = ?", Date.today)
  
      # Mettre à jour l'intervention ou créer une nouvelle
      if current_intervention
        unless current_intervention.fin
          current_intervention.fin = DateTime.now
          current_intervention.temps_total = current_intervention.calc_temps_total
          current_intervention.workflow_state = "terminé"
          current_intervention.save
          flash[:notice] = "Fin de journée enregistrée"
        else
          flash[:alert] = "Fin de journée déjà enregistrée !"
        end
      else
        current_intervention = @intervention.create_next_intervention
        flash[:notice] = "Début de journée enregistrée"
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

  def carte_interventions

    if current_user.adhérent?
      @interventions = current_user.organisation.interventions.ordered
    else
      @interventions = Intervention.by_role_for(current_user)
    end

    if params[:date].blank?
      params[:date] = DateTime.now
    end
    # Conversion nécessaire pour le repasser dans la vue dans la fonction l()
    @date_to_string = params[:date].to_s
    time_zone_date = Time.zone.parse(@date_to_string)

    @interventions = @interventions.where(
      "début <= ? AND fin >= ?", time_zone_date, time_zone_date
    )

    organisation_members = current_user.organisation.users
    if current_user.manager?
      @adhérents = organisation_members.adhérent.order(:nom)
      @services = User.services.sort
      @teams = organisation_members.équipe
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.adhérent?
      @adhérents = organisation_members.adhérent.order(:nom)
      @services = User.services
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.équipe?
      @services = User.services
      @grouped_agents = User.grouped_agents(organisation_members)
    elsif current_user.agent?
      @adhérents = organisation_members.adhérent.order(:nom)
    end

    # Faire en sorte quand adhérent, chercher les interventions avec l'outil en params. Sauf que avant, si adhérent, alors chercher toutes les interventions de l'organisation

    if params[:tool_ids].present?
      @interventions = @interventions.joins(:tool_interventions).where(tool_interventions: {tool_id: params[:tool_ids]})
    end

    @tools = current_user.organisation.tools.ordered
    @tags = @interventions.tag_counts_on(:tags).order(tags_count: :desc).order(:name)


    if params[:workflow_state].present?
      @interventions = @interventions.where("interventions.workflow_state = ?", params[:workflow_state].to_s.downcase)
    end

    if params[:search].present?
      @interventions = @interventions.where("description ILIKE :search OR commentaires ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:adherent_id].present?
      @interventions = @interventions.where(adherent_id: params[:adherent_id])
    end

    if params[:team_id].present?
      @interventions = @interventions.where(team_id: params[:team_id])
    end

    if params[:service].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {service: params[:service]})
    end

    if params[:agent_ids].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {id: params[:agent_ids]})
    end

    if params[:tags].present?
      @interventions = @interventions.tagged_with(params[:tags].reject(&:blank?))
      session[:tags] = params[:tags]
    else
      session[:tags] = params[:tags] = []
    end
    
    @interventions_localisations_to_marker = Hash.new
    if @interventions.any?

      # Groupage des interventions en fonction des adhérents pour n'avoir qu'un marker par adhérent
      interventions_par_adherent = @interventions.group_by(&:adherent_id)

      @interventions_localisations_to_marker = interventions_par_adherent.map{
        |adherent_id, interventions|
        adherent = User.find(adherent_id)
        { 
          position: adherent.lat_lng_object,
          title: interventions.map {
            |intervention|
            agent_name = intervention.agents.any? ? "#{intervention.agents.first.nom_prénom}, " : ""
            "#{agent_name}#{intervention.description}, #{intervention.début}/#{intervention.fin}"
          }.join(" | "),
          adherent_slug: adherent.slug,
        }
      }
    end
  end

  private

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
      @tags = current_user.organisation.interventions.tag_counts_on(:tags).order(:name)
      @organisation_members = current_user.organisation.users
      @équipes = @organisation_members.équipe
      @grouped_agents = User.grouped_agents(@organisation_members)
      @tools = current_user.organisation.tools.ordered
    end

    # Only allow a list of trusted parameters through.
    def intervention_params
      params.require(:intervention).permit(:organisation_id, :adherent_id, :team_id, :début, :début_hour, :début_minute, :fin, :fin_hour, :fin_minute, :temps_de_pause, :temps_total, :description, :commentaires, :workflow_state, :tag_list, :note, :avis, :repeter, :début_prévue, :début_prévue_hour, :début_prévue_minute, :fin_prévue, :fin_prévue_hour, :fin_prévue_minute , photos: [], agent_ids: [], tool_ids: [])
    end

    def is_user_authorized
      authorize @intervention ? @intervention : Intervention
    end

    def store_return_location
      session[:return_to] = request.referer if request.referer.present? && URI(request.referer).host == request.host
    end

    def update_tag_list
      if current_user.manager?
        @intervention.tag_list = params[:intervention][:tags_manager]
      else
        @intervention.tag_list = params[:intervention][:tags]
      end
    end

    # Ajoute ou enlève l'état 'attente' selon si c'est un modèle de pointage.
    def check_workflow_pointage_mère
      if !@intervention.repeter? && @intervention.workflow_state == 'attente'
        @intervention.workflow_state = 'nouveau'
      elsif @intervention.repeter? && @intervention.workflow_state != 'attente'
        @intervention.workflow_state = 'attente'
      end
    end

end
