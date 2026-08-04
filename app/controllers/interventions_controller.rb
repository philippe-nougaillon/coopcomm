# frozen_string_literal: true

class InterventionsController < ApplicationController
  before_action :set_intervention,
                only: %i[show edit update destroy terminer valider refuser archiver purge pointer pointage_statut
                         update_location]
  before_action :is_user_authorized
  before_action :set_form_variables,
                only: %i[new edit create update new_intervention_modele_pointage create_intervention_modele_pointage]
  before_action :store_return_location, only: %i[new edit]

  # Déclaré dans application_controller.rb
  before_action :set_users_tags, only: [:index]

  before_action :set_interventions_tags,
                only: %i[index new edit create update new_intervention_modele_pointage create_intervention_modele_pointage]


  # GET /interventions or /interventions.json
  def index
    session[:vue] ||= 'normal'
    params[:vue] ||= session[:vue]

    # Filtre en fonction du rôle de l'utilisateur
    @interventions = Intervention.by_role_for(current_user)

    selected_services = scoped_services(:service, admin_sees_all: true)

    # Filtre sur les services
    if current_user.manager_or_admin? || @selected_service_ids.present?
      @interventions = @interventions.filter_by_service(selected_services)
    end

    # Le select est `multiple` : tableau de libellés humanisés (ex. ["Nouveau"]).
    selected_states = Array(params[:workflow_state]).reject(&:blank?).map(&:downcase)

    @interventions = if params[:archives].present?
                       @interventions.where(workflow_state: 'archivé')
                     elsif selected_states.any?
                       @interventions.where(workflow_state: selected_states)
                     else
                       @interventions.where.not(workflow_state: 'archivé')
                     end

    # Enlever les interventions filles si ce n'est pas un adhérent
    # @interventions = @interventions.where(template_slug: nil) unless current_user.adhérent?

    if params[:search].present?
      @interventions = @interventions.where('description ILIKE :search OR commentaires ILIKE :search',
                                            { search: "%#{params[:search]}%" })
    end

    if params[:du].present?
      if params[:au].present?
        @interventions = @interventions.where('DATE(début) BETWEEN ? AND ?', params[:du], params[:au])
      else
        @interventions = @interventions.where('DATE(début) = ?',
                                              params[:du]).or(@interventions.where('DATE(fin) = ?', params[:du]))
      end
    elsif params[:au].present?
      @interventions = @interventions.where('DATE(fin) = ?', params[:au])
    end

    @interventions = @interventions.where(adherent_id: params[:adherent_id]) if params[:adherent_id].present?

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
      @interventions = @interventions.joins(agent_interventions: :agent).where(agent: { id: params[:agent_ids] })
    end

    if params[:tool_ids].present?
      @interventions = @interventions.joins(:tool_interventions).where(tool_interventions: { tool_id: params[:tool_ids] })
    end

    if params[:tags].present?
      @interventions = @interventions.tagged_with(params[:tags].reject(&:blank?))
      session[:tags] = params[:tags]
    else
      session[:tags] = params[:tags] = []
    end

    @interventions = @interventions.reorder(Arel.sql("#{sort_column} #{sort_direction}")) if params[:vue] == 'compact'

    @interventions = @interventions.distinct

    users_in_same_services = User.by_service(selected_services)

    adherents_services = current_user.administrateur? ? @services : selected_services
    @adhérents = User.by_service(adherents_services).adhérent.order(:nom)

    if current_user.manager_or_admin? || current_user.adhérent?
      @grouped_agents = users_in_same_services.grouped_agents(current_user)
    end

    @tools = current_organisation.tools.ordered

    session[:vue] = params[:vue]

    @interventions = @interventions.includes(:tags, :agents, :adherent, :service, :organisation,
                                             :tools).with_attached_photos

    
    respond_to do |format|
      format.html do
        @pagy, @interventions = pagy(@interventions)
      end

      format.xls do
        xls_file = ExportToXls::Interventions.call(@interventions, include_evaluation: !current_user.agent?)
        send_data xls_file, filename: "Interventions_#{l Date.today}.xls"
      end
    end
  end




  # GET /interventions/1 or /interventions/1.json
  def show
    # TODO : Déplacer le stale au plus près du render
    # if stale?(@intervention)

    if @intervention.repeter?
      @pointages = if current_user.agent?
                     current_user.interventions.where(template_slug: @intervention.slug, repeter: false)
                   else
                     @intervention.pointages
                   end
      @pointages = @pointages.ordered
    end

    if (@intervention.nouveau? || @intervention.trajet.blank?)
      @routes_response = @intervention.get_routes_info_from_location
    end

    respond_to do |format|
      format.html do
        @audits = @intervention.own_and_associated_audits.includes(:user).reorder(id: :desc)
        @pagy, @audits = pagy(@audits, items: 10)
      end

      format.pdf do
        authorize @intervention, :can_see_qrcode_pointage_pdf?

        pdf = TransformToPdf::QrcodeModeleIntervention.call(@intervention)

        send_data pdf.render,
                  filename: "QRCode_Pointeuse_#{@intervention.description}.pdf",
                  type: 'application/pdf',
                  disposition: 'inline'
      end
    end
  end

  # GET /interventions/new
  def new
    @intervention = Intervention.new

    if current_user.agent?
      @intervention.agent_ids = current_user.id

      # Par défaut, un agent saisi une intervention après l'avoir réalisé (le soir)
      @intervention.workflow_state = 'terminé'
    else
      # Si on passe par le planning des agents
      @intervention.agent_ids = params[:agent_id]
    end

    # Ajout de la date de fin si c'est un agent et que la date début prévue et fin prévue sont nil
    return unless current_user.agent? && (params[:début_prévue].blank? || params[:fin_prévue].blank?)

    @intervention.fin = DateTime.now
  end

  # GET /interventions/1/edit
  def edit; end

  # POST /interventions or /interventions.json
  def create
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_organisation
    @intervention.workflow_state = Intervention::TERMINE if current_user.agent?
    update_tag_list

    respond_to do |format|
      if @intervention.save
        format.html { redirect_to intervention_url(@intervention), notice: 'Intervention créée avec succès.', status: :see_other }
        format.json { render :show, status: :created, location: @intervention }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @intervention.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /interventions/1 or /interventions/1.json
  def update
    terminaison_demandée = false
    enregistrée = false

    # agent_ids= et tool_ids= écrivent les lignes de jointure dès l'assignation :
    # sans transaction, un refus de validation les laisserait en base.
    ActiveRecord::Base.transaction do
      @intervention.assign_attributes(intervention_params)
      update_tag_list

      terminaison_demandée = params[:terminer].present? && @intervention.can_terminer? &&
                             policy(@intervention).terminer?
      @intervention.workflow_state = Intervention::TERMINE if terminaison_demandée

      enregistrée = @intervention.save
      raise ActiveRecord::Rollback unless enregistrée
    end

    respond_to do |format|
      if enregistrée

        format.html do
          # Si c'est une modification du commentaire dans le pointage statut, on redirige vers home
          # 303 obligatoire après un PATCH Turbo : en 302 la page reste figée sur le formulaire.
          if params[:commit] == 'Enregistrer le commentaire'
            redirect_to root_path, notice: 'Votre commentaire a été enregistré', status: :see_other
          elsif terminaison_demandée
            redirect_to intervention_url(@intervention), notice: 'Intervention terminée', status: :see_other
          else
            redirect_to intervention_url(@intervention), notice: 'Intervention modifiée avec succès.', status: :see_other
          end
        end
        format.json { render :show, status: :ok, location: @intervention }
      else
        # L'état n'a pas été enregistré : le formulaire ne doit pas afficher « Terminé ».
        @intervention.restore_attributes([:workflow_state]) if terminaison_demandée

        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @intervention.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /interventions/1 or /interventions/1.json
  def destroy
    respond_to do |format|
      if @intervention.destroy
        # 303 : un fetch qui suit un 302 après DELETE peut rejouer le DELETE sur la cible
        format.html { redirect_to interventions_url, notice: 'Intervention supprimée avec succès.', status: :see_other }
        format.json { head :no_content }
      else
        # Nécessaire s'il y a des erreurs
        flash[:alert] = "L'intervention ne peut pas être supprimée : #{@intervention.errors.full_messages.join(', ')}"
        # see_other = erreur 303 = Redirection après échec de suppression
        format.html do
          redirect_to @intervention, status: :see_other
        end
      end
    end
  end

  # def accepter
  #   @intervention.accepter!
  #   # Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: @intervention.id })
  #   redirect_to @intervention, notice: "Intervention acceptée"
  # end

  # def en_cours
  #   @intervention.en_cours!
  #   # Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: @intervention.id })
  #   redirect_to @intervention, notice: "Intervention en cours"
  # end

  def terminer
    return if redirect_si_invalide('terminée', etat_cible: Intervention::TERMINE)

    if @intervention.can_terminer?
      @intervention.terminer!

      redirect_to @intervention, notice: 'Intervention terminée'
    else
      redirect_to @intervention, alert: "Impossible de terminer l'intervention"
    end
  end

  def valider
    return if redirect_si_invalide('validée')

    @intervention.valider!

    Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: @intervention.id }) unless Rails.env.development?

    redirect_to @intervention, notice: 'Intervention validée'
  end

  def refuser
    return if redirect_si_invalide('refusée')

    @intervention.refuser!

    Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: @intervention.id }) unless Rails.env.development?

    redirect_to @intervention, notice: 'Intervention refusée'
  end

  def archiver
    if @intervention.valid?
      if @intervention.can_archiver?
        @intervention.archiver!
        
        Events.instance.publish('intervention.workflow_changed', payload: { intervention_id: @intervention.id }) unless Rails.env.development?

        redirect_to @intervention, notice: 'Intervention archivée'
      elsif @intervention.archivé?
        redirect_to @intervention, alert: "L'intervention est déjà archivée"
      else
        redirect_to @intervention, alert: "L'intervention ne peut pas se archiver"
      end
    else
      redirect_to @intervention, alert: "L'intervention n'est pas valide. Elle ne peut pas être archivée"
    end
  end

  def purge
    @intervention.photos.find(params[:photo_id]).purge
    @intervention.update(audit_comment: "Photo n°#{params[:photo_id]} supprimée")
    redirect_to @intervention, notice: 'Photo supprimée', status: :see_other
  end

  def pointer
    if @intervention.repeter?
      # Intervention fille se passant aujourd'hui (intervention en cours de réalisation)
      current_intervention = current_user.find_current_intervention(@intervention.slug)

      # Si une intervention fille existe déjà, on la met à jour, sinon on en créée une nouvelle
      if current_intervention.present?
        if current_intervention.fin
          current_intervention = @intervention.create_next_intervention(@intervention, current_user)
          message = "Reprise d'activité enregistrée !"
        else
          current_intervention.fin = DateTime.now
          current_intervention.workflow_state = 'terminé'
          current_intervention.save
          message = 'Pointage de fin enregistré !'
        end
      else
        current_intervention = @intervention.create_next_intervention(@intervention, current_user)
        message = 'Début de journée enregistré !'
      end

      unless current_intervention.persisted? && current_intervention.errors.empty?
        return redirect_to @intervention,
                           alert: "Le pointage n'a pas pu être enregistré : #{current_intervention.errors.full_messages.to_sentence}"
      end

      flash[:notice] = message
      
      Events.instance.publish('intervention.pointage', payload: { intervention_id: current_intervention.id }) unless Rails.env.development?

      redirect_to pointage_statut_intervention_path(current_intervention)
    else
      redirect_to @intervention, alert: "Cette intervention n'est pas un modèle de pointage"
    end
  end

  def pointage_statut
    return unless @intervention.repeter

    redirect_to pointage_statut_intervention_path(Intervention.find_by(template_slug: @intervention.slug))
  end

  def update_location
    if @intervention.update(localisation: "#{params[:latitude]}, #{params[:longitude]}")
      render json: { status: 'success' }, status: :ok
    else
      render json: { errors: @intervention.errors.full_messages }, status: :unprocessable_content
    end
  end

  # TODO VU : si ça sert encore, déplacer ce bloc dans le model
  # On appelle ça dans un stimulus_controller, on ne peut pas tout déplacer dans le model.
  
  # Récupère les agents en conflit avec les dates passées dans l'URL
  def get_unavailable_elements
    # Récupération des données dans l'url
    # TODO VU : La valeur "null" doit être évité à partir du stimulus
    intervention_id = params['intervention_id'] != 'null' ? params['intervention_id'] : nil
    date_debut_prevue = params['date_debut_prevue'] != 'null' ? params['date_debut_prevue'] : nil
    date_fin_prevue = params['date_fin_prevue'] != 'null' ? params['date_fin_prevue'] : nil
    date_debut_reel = params['date_debut'] != 'null' ? params['date_debut'] : nil
    date_fin_reel = params['date_fin'] != 'null' ? params['date_fin'] : nil

    # TODO : Ne prendre en compte qu'une seule date (date_réelle || date_prévue)
    date_debut = date_debut_reel.presence || date_debut_prevue
    date_fin = date_fin_reel.presence || date_fin_prevue

    agent_ids_string = params['agents_ids'] != 'null' ? params['agents_ids'] : nil
    # Transforme le string en liste d'agents id
    agent_ids = agent_ids_string.split(',').map(&:to_i) if params['agents_ids']

    conflicting_agents_ids = []
    conflicting_tool_ids = []

    if agent_ids
      # TODO VU : mettre le contenu dans "get_unavailable_agents_with_interventions". "get_unavailable_agents" doit appeler "get_unavailable_agents_with_interventions" et "get_unavailable_agents_with_absences"
      conflicting_agents_ids = Intervention.get_unavailable_agents(intervention_id, agent_ids, date_debut,
                                                                   date_fin)
      conflicting_agents_ids += Intervention.get_unavailable_agents_with_absences(agent_ids, date_debut,
                                                                                  date_fin)
      conflicting_agents_ids.uniq
    end

    tool_ids_string = params['tool_ids'] != 'null' ? params['tool_ids'] : nil
    # Transforme le string en liste d'agents id
    tool_ids = tool_ids_string.split(',').map(&:to_i) if params['tool_ids']

    if tool_ids
      conflicting_tool_ids = Intervention.get_unavailable_tools(intervention_id, tool_ids, date_debut,
                                                                date_fin)
    end

    json = {
      "agents": conflicting_agents_ids,
      "tools": conflicting_tool_ids
    }

    render json: json, status: :ok
  end

  # TODO VU : déplacer ce bloc dans le model

  def services_for_adherent
    adherent = User.find(params[:adherent_id])
    @services = adherent.services.where(id: current_user.service_ids)

    # On renvoie uniquement l'id et le nom pour construire le <select>
    render json: @services.select(:id, :nom)
  end

  def agents_for_service
    service = current_user.services.find_by(id: params[:service_id]) if params[:service_id].present?

    agents = User.agents_for_services(service ? [service] : current_user.services)

    render json: agents.map { |nom, id| { id: id, nom: nom } }
  end

  # Pour créer une intervention pointage
  def new_intervention_modele_pointage
    @intervention = Intervention.new
    @intervention.repeter = true
  end

  def create_intervention_modele_pointage
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_organisation

    # Force l'intervention à être répété
    @intervention.repeter = true
    @intervention.workflow_state = 'pointage activé'

    update_tag_list

    respond_to do |format|
      if @intervention.save
        format.html { redirect_to intervention_url(@intervention), notice: 'Modèle de pointage créé avec succès.' }
        format.json { render :show, status: :created, location: @intervention }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @intervention.errors, status: :unprocessable_content }
      end
    end
  end

  private

  def get_routage_responses; end

  # TODO VU : à supprimer s'il n'y a pas d'optique d'amélioration sur la carte google, sinon, déplacer ce bloc dans le model

  # def get_interventions_localisations_to_marker(interventions_par_adherent)
  #   interventions_par_adherent.map do |adherent_id, interventions|
  #     adherent = User.find(adherent_id)
  #     {
  #       position: adherent.localisation_to_lat_lng_object,
  #       title: interventions.map do |intervention|
  #         agent_name = intervention.agents.any? ? "#{intervention.agents.first.nom_prénom}, " : ''
  #         "#{agent_name}#{intervention.description}, #{intervention.début}/#{intervention.fin}"
  #       end.join(' | '),
  #       adherent_slug: User.find(adherent_id).slug
  #     }
  #   end
  # end

  # Use callbacks to share common setup or constraints between actions.
  def set_intervention
    @intervention = Intervention.find_by(slug: params[:id])
    return unless @intervention.nil?

    redirect_to root_path, alert: 'Intervention introuvable'
  end

  def set_form_variables
    services = current_user.services
    @services = services unless current_user.agent?

    users_in_same_services = User.by_service(services)

    @adhérents = users_in_same_services.adhérent.order(:nom)

    selected_service = preselected_form_service
    @agents = User.agents_for_services(selected_service ? [selected_service] : services)

    @tools = current_organisation.tools.ordered
  end

  def preselected_form_service
    service_id = @intervention&.service_id || params[:service_id]
    service_id ||= current_user.services.first&.id if current_user.agent?
    return nil if service_id.blank?

    current_user.services.find_by(id: service_id)
  end

  def set_interventions_tags
    @intervention_tags = current_organisation.interventions.tag_counts_on(:tags).order(:name)
  end

  # Only allow a list of trusted parameters through.
  # :workflow_state, :note et :avis sont volontairement exclus du mass assignment.
  def intervention_params
    permitted = params.require(:intervention).permit(:adherent_id, :service_id, :début, :début_hour, :début_minute, :fin,
                                                     :fin_hour, :fin_minute, :temps_de_pause, :temps_total, :description, :commentaires, :tag_list, :repeter, :début_prévue, :début_prévue_hour, :début_prévue_minute, :fin_prévue, :fin_prévue_hour, :fin_prévue_minute, :meteo, photos: [], agent_ids: [], tool_ids: [])
    permitted.merge!(params.require(:intervention).permit(:note, :avis)) if current_user.adhérent? || current_user.manager_or_admin?
    permitted
  end

  def is_user_authorized
    authorize @intervention || Intervention
  end

  def store_return_location
    session[:return_to] = request.referer if request.referer.present? && URI(request.referer).host == request.host
  end

  def update_tag_list
    @intervention.tag_list = if current_user.manager_or_admin?
                               params[:intervention][:tags_manager]
                             else
                               params[:intervention][:tags_intervenant]
                             end
  end

  def sortable_columns
    ['interventions.description', 'interventions.commentaires', 'interventions.début_prévue',
     'interventions.fin_prévue', 'interventions.temps_total', 'interventions.updated_at', 'interventions.workflow_state']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'interventions.updated_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end

  def redirect_si_invalide(etat, etat_cible: nil)
    @intervention.workflow_state = etat_cible if etat_cible
    valide = @intervention.valid?
    @intervention.restore_attributes([:workflow_state]) if etat_cible
    return false if valide

    motifs = @intervention.errors.full_messages.map(&:strip).to_sentence
    redirect_to @intervention,
                alert: "L'intervention n'est pas valide, elle ne peut pas être #{etat} : #{motifs}"
    true
  end
end
