class InterventionsController < ApplicationController
  before_action :set_intervention, only: %i[ show edit update destroy accepter en_cours terminer valider refuser archiver purge pointer pointage_statut ]
  before_action :set_form_variables, only: %i[ new edit create update ]
  before_action :is_user_authorized, except: %i[ pointer pointage_statut ]
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
      @services = User.services
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
    @tags = @interventions.tag_counts_on(:tags).order(tags_count: :desc).order(:name)

    if params[:search].present?
      @interventions = @interventions.where("description ILIKE :search OR commentaires ILIKE :search", {search: "%#{params[:search]}%"})
    end

    if params[:adherent_id].present?
      @interventions = @interventions.where(adherent_id: params[:adherent_id])
    end

    if params[:team_id].present?
      @interventions = @interventions.where(user_id: params[:team_id])
    end

    if params[:service].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {service: params[:service]})
    end

    if params[:agent_id].present?
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: {id: params[:agent_id]})
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

    if params[:tags].present?
      @interventions = @interventions.tagged_with(params[:tags].reject(&:blank?))
      session[:tags] = params[:tags]
    else
      session[:tags] = params[:tags] = []
    end

    respond_to do |format|
      format.html do
        @pagy, @interventions = pagy(@interventions.includes(:tags, :user, :agents, :adherent).with_attached_photos)
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
        filename = "QRCode_Pointeuse_#{@intervention.agents.first.nom_prénom}"
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
    @intervention.agent_ids = current_user.id if current_user.agent?
  end

  # GET /interventions/1/edit
  def edit
  end

  # POST /interventions or /interventions.json
  def create
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_user.organisation
    if current_user.manager?
      @intervention.tag_list.add(params[:intervention][:tags_manager])
    else
      @intervention.user_id ||= current_user.id
      @intervention.tag_list.add(params[:intervention][:tags])
    end

    if @intervention.nouveau? && @intervention.repeter?
      @intervention.workflow_state = 'attente'
    end

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
    respond_to do |format|
      if @intervention.update(intervention_params)
        if current_user.manager?
          @intervention.tag_list = params[:intervention][:tags_manager]
        else
          @intervention.tag_list = params[:intervention][:tags]
        end
        @intervention.save
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

  def accepter
    @intervention.accepter!
    # send_workflow_changed_notification
    redirect_to @intervention, notice: "Intervention acceptée"
  end

  def en_cours
    @intervention.en_cours!
    # send_workflow_changed_notification
    redirect_to @intervention, notice: "Intervention en cours"
  end

  def terminer
    @intervention.terminer!
    send_workflow_changed_notification
    send_intervention_termine_notification
    redirect_to @intervention, notice: "Intervention terminée"
  end

  def valider
    @intervention.valider!
    # send_workflow_changed_notification
    if current_user.adhérent?
      terminé = true
    end
    redirect_to edit_intervention_path(@intervention, terminé: terminé), notice: "Intervention validée"
  end

  def refuser
    @intervention.refuser!
    # send_workflow_changed_notification
    if current_user.adhérent?
      terminé = true
    end
    redirect_to edit_intervention_path(@intervention, terminé: terminé), notice: "Intervention refusée"
  end

  def archiver
    @intervention.archiver!
  #   send_workflow_changed_notification
    redirect_to @intervention, notice: "Intervention archivée"
  end

  def purge
    @intervention.photos.find(params[:photo_id]).purge
    @intervention.update(audit_comment: "Photo n°#{params[:photo_id]} supprimée")
    redirect_to @intervention, notice: "Photo supprimée"
  end

  def pointer
    # Prendre l'intervention la plus récente
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
  end

  def pointage_statut
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
    end

    def set_form_variables
      @tags = current_user.organisation.interventions.tag_counts_on(:tags).order(:name)
      @organisation_members = current_user.organisation.users
      @équipes = @organisation_members.équipe
      @grouped_agents = User.grouped_agents(@organisation_members)
    end

    # Only allow a list of trusted parameters through.
    def intervention_params
      params.require(:intervention).permit(:organisation_id, :adherent_id, :user_id, :début, :fin, :temps_de_pause, :temps_total, :description, :commentaires, :workflow_state, :tag_list, :note, :avis, :repeter, :repeter_lun, :repeter_mar, :repeter_mer, :repeter_jeu, :repeter_ven, :repeter_sam, :repeter_dim, :fin_repeter, photos: [], agent_ids: [])
    end

    def is_user_authorized
      authorize @intervention ? @intervention : Intervention
    end

end
