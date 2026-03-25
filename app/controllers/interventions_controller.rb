class InterventionsController < ApplicationController
  before_action :set_intervention, only: %i[ show edit update destroy terminer valider refuser archiver purge pointer pointage_statut ]
  before_action :set_form_variables, only: %i[ new edit create update ]
  before_action :is_user_authorized
  before_action :store_return_location, only: [:new, :edit]
  skip_before_action :authenticate_user!
  before_action :set_organisation_user_tags, only: [:index]

  # GET /interventions or /interventions.json
  def index
    session[:vue] ||= 'normal'
    params[:vue] ||= session[:vue]

    @interventions = Intervention.by_role_for(current_user)
    if params[:archives].present?
      @interventions = @interventions.where(workflow_state: 'archivé')
    elsif params[:workflow_state].present?
      @interventions = @interventions.where("interventions.workflow_state = ?", params[:workflow_state].to_s.downcase)
    else
      @interventions = @interventions.where.not(workflow_state: 'archivé')
    end

    # Enlever les interventions filles
    @interventions = @interventions.where(template_slug: nil)

    @services = current_user.services

    @interventions = @interventions.filter_by_service(params[:service].presence || @services )

    organisation_members = current_user.organisation.users.filter_by_service(params[:service].presence || @services)
    @adhérents = organisation_members.adhérent.order(:nom)
    if current_user.manager_or_admin? || current_user.adhérent?
      @grouped_agents = User.grouped_agents(current_user)
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

    if params[:equipe].present?
      # On nettoie le tableau pour enlever l'élément vide ("") envoyé par le formulaire
      tags = params[:equipe].reject(&:blank?)
      
      if tags.any?
        adherent_ids = User.tagged_with(tags, any: true).pluck(:id)

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

    session[:vue] = params[:vue]

    @interventions = @interventions.distinct
    respond_to do |format|
      format.html do
        @pagy, @interventions = pagy(@interventions.includes(:tags, :team, :agents, :adherent).with_attached_photos)
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

      unless Rails.env.test?
        # Pour la map avec la route entre l'intervention courant et le siège de la communauté de commune
        if @intervention.adherent.present? && @intervention.adherent.localisation.present?
          if @intervention.trajet.blank? || @intervention.nouveau?
            # Prendre l'adhérent de l'intervention
            localisation_arrivee = @intervention.adherent.localisation_to_lat_lng_object

            # Création du service avec l'intervention de destination
            request = ApiGoogleMaps.new(localisation_arrivee)

            request.call

            # Récupération des données via les getters du service
            @localisation_depart = request.localisation_depart
            @localisation_arrivee = localisation_arrivee
            @errors = request.errors
            @routes_info = request.routes_info
            @response = request.data_response
          end
        end
      end

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
      date_fin = now - now.minute.modulo(5).minute

      @intervention.fin = date_fin
    end
  end

  # GET /interventions/1/edit
  def edit
  end

  # POST /interventions or /interventions.json
  def create
    @intervention = Intervention.new(intervention_params)
    @intervention.organisation = current_user.organisation
    update_tag_list

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
    @intervention.terminer!
    @intervention.calculate_co2

    send_workflow_changed_notification
    send_intervention_termine_notification

    redirect_to @intervention, notice: "Intervention terminée"
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

    # Si c'est un adhérent, on va chercher toutes les interventions du jour, sans distinction du rôle pour pouvoir trier par outils après.
    if current_user.adhérent?
      @interventions = current_user.organisation.interventions.ordered
    else
      @interventions = Intervention.by_role_for(current_user)
    end

    # Pour que la carte ne plante pas (il faut une position d'un adhérent)
    @interventions = @interventions.where.not(adherent_id: nil)

    if params[:date].blank?
      params[:date] = DateTime.now
    end
    # Conversion nécessaire pour le repasser dans la vue dans la fonction l(). On passe de DateTime à un string
    @date_to_string = params[:date].to_s

    # Besoin de parser avec le timezone pour éviter des décalages horaires
    time_zone_date = Time.zone.parse(@date_to_string)

    # # Recherche de toutes les interventions qui se passent dans la date
    @interventions = @interventions.where(
      "début <= ? AND fin >= ?", time_zone_date, time_zone_date
    )

    # Changé pour l'instant pour tester les routes entre deux interventions parce que ça n'a pas de sens de relier deux interventions qui ont lieu en même temps/
    # Commenter cette ligne et décommenter celle du dessus pour revenir à la méthode initiale
    @interventions = @interventions.where("DATE(début) = ?", time_zone_date.to_date)

    # Création des variables utilisés par les selecteurs
    organisation_members = current_user.organisation.users.filter_by_service(current_user.services)
    @adhérents = organisation_members.adhérent.order(:nom)
    if current_user.manager_or_admin? || current_user.adhérent?
      @services = current_user.services.sort
      @grouped_agents = User.grouped_agents(current_user)
    end
    @tools = current_user.organisation.tools.ordered
    @tags = @interventions.tag_counts_on(:tags).order(tags_count: :desc).order(:name)


    # Filtrage des interventions en fonction des paramètres

    if params[:tool_ids].present?
      @interventions = @interventions.joins(:tool_interventions).where(tool_interventions: {tool_id: params[:tool_ids]})
    end

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
    
    # Centre de la carte en fonction de l'adhérent ou d'un localisation par défaut, ici La Défense.
    @map_center = current_user.adhérent? ? current_user.localisation_to_lat_lng_object : { lat: 48.89084994828303, lng: 2.2416654776359355 }

    # Initialisation des variables utilisées dans la vue
    @interventions_localisations_to_marker = Hash.new
    @routes_info = []
    @error_message = []

    if @interventions.any?
      # Groupage des interventions en fonction des adhérents pour n'avoir qu'un marker par adhérent
      interventions_par_adherent = @interventions.group_by(&:adherent_id)

      # Variable contenant toutes les informations pour les markers
      @interventions_localisations_to_marker = get_interventions_localisations_to_marker(interventions_par_adherent)

      @map_center = calculate_map_center(@interventions_localisations_to_marker)

      # Si l'utilisateur courant est un adhérent, calculer les trajets entre lui et les autres interventions trouvées. Pour l'instant en stand-by tant que l'on a pas de réels besoins client.
      if current_user.adhérent?
        request = ApiGoogleMaps.new
        localisation_current_adhérent = current_user.localisation_to_lat_lng_object
      
        @errors = []
        @interventions_localisations_to_marker.each do 
          |intervention, index|
          if intervention[:position] == localisation_current_adhérent
            next
          end
          destination_lat = intervention[:position][:lat]
          destination_lng = intervention[:position][:lng]
      
          body = {
            origin: {
              location: {
                latLng: {
                  latitude: localisation_current_adhérent[:lat],
                  longitude: localisation_current_adhérent[:lng]
                }
              }
            },
            destination: {
              location: {
                latLng: {
                  latitude: destination_lat,
                  longitude: destination_lng
                }
              }
            },
            travelMode: "DRIVE",
          }
      
          request.prepare_body_request(body)
          response = request.get_response
      
          if response["error"]
            @errors << { position: intervention[:position], message: response["error"]["message"] }
          else
            @routes_info << "Adhérent slug = #{intervention[:adherent_slug]}, Distance = #{response["routes"].first["distanceMeters"].to_f/1000} km , Durée = #{response["routes"].first["duration"].to_f/60} min; "
          end
        end
      end
    end
  end

  def route_interventions

    # Si c'est un adhérent, on va chercher toutes les interventions du jour, sans distinction du rôle pour pouvoir trier par outils après.
    if current_user.adhérent?
      @interventions = current_user.organisation.interventions.ordered
    else
      @interventions = Intervention.by_role_for(current_user)
    end

    # Pour que la carte ne plante pas (il faut une position d'un adhérent)
    @interventions = @interventions.where.not(adherent_id: nil)

    if params[:date].blank?
      params[:date] = DateTime.now
    end
    # Conversion nécessaire pour le repasser dans la vue dans la fonction l(). On passe de DateTime à un string
    @date_to_string = params[:date].to_s

    # Besoin de parser avec le timezone pour éviter des décalages horaires
    time_zone_date = Time.zone.parse(@date_to_string)


    @interventions = @interventions.where("DATE(début) = ?", time_zone_date.to_date)

    # Création des variables utilisés par les selecteurs
    organisation_members = current_user.organisation.users.filter_by_service(current_user.services)
    @adhérents = organisation_members.adhérent.order(:nom)
    if current_user.manager_or_admin? || current_user.adhérent?
      @services = current_user.services.sort
      @grouped_agents = User.grouped_agents(current_user)
    end
    @tools = current_user.organisation.tools.ordered
    @tags = @interventions.tag_counts_on(:tags).order(tags_count: :desc).order(:name)


    # Filtrage des interventions en fonction des paramètres

    if params[:tool_ids].present?
      @interventions = @interventions.joins(:tool_interventions).where(tool_interventions: {tool_id: params[:tool_ids]})
    end

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
    
    # Centre de la carte en fonction de l'adhérent ou d'un localisation par défaut, ici La Défense.
    @map_center = current_user.adhérent? ? current_user.localisation_to_lat_lng_object : { lat: 48.89084994828303, lng: 2.2416654776359355 }

    # Initialisation des variables utilisées dans la vue
    @interventions_localisations_to_marker = Hash.new
    @routes_info = []
    @error_message = []

    @interventions = @interventions.last(2)

    if @interventions.any?
      # Groupage des interventions en fonction des adhérents pour n'avoir qu'un marker par adhérent
      interventions_par_adherent = @interventions.group_by(&:adherent_id)

      # Variable contenant toutes les informations pour les markers
      @interventions_localisations_to_marker = get_interventions_localisations_to_marker(interventions_par_adherent)

      @map_center = calculate_map_center(@interventions_localisations_to_marker)

      # Si l'utilisateur courant est un adhérent, calculer les trajets entre lui et les autres interventions trouvées. Pour l'instant en stand-by tant que l'on a pas de réels besoins client.
      if current_user.adhérent?
        request = ApiGoogleMaps.new
        localisation_current_adhérent = current_user.localisation_to_lat_lng_object

        # Prendre la route de thiaucourt vers l'adhérent courant

        @errors = []

        @interventions_localisations_to_marker
        @interventions_localisations_to_marker

        # @interventions_localisations_to_marker.each do
        #   |intervention, index|
        #   if intervention[:position] == localisation_current_adhérent
        #     next
        #   end
        #   destination_lat = intervention[:position][:lat]
        #   destination_lng = intervention[:position][:lng]
        #
        #   body = {
        #     origin: {
        #       location: {
        #         latLng: {
        #           latitude: localisation_current_adhérent[:lat],
        #           longitude: localisation_current_adhérent[:lng]
        #         }
        #       }
        #     },
        #     destination: {
        #       location: {
        #         latLng: {
        #           latitude: destination_lat,
        #           longitude: destination_lng
        #         }
        #       }
        #     },
        #     travelMode: "DRIVE",
        #     extraComputations: "FUEL_CONSUMPTION",
        #     routingPreference: "TRAFFIC_AWARE_OPTIMAL",
        #     requestedReferenceRoutes: ["FUEL_EFFICIENT"]
        #   }
        #
        #   request.prepare_body_request(body)
        #   response = request.get_response
        #   @response = nil
        #
        #   if response["error"]
        #     @errors << { position: intervention[:position], message: response["error"]["message"] }
        #   else
        #     route = response["routes"].first
        #
        #     # 💡 Consommation de carburant
        #     fuel_microliters = route.dig("travelAdvisory", "fuelConsumptionMicroliters")
        #     fuel_liters = fuel_microliters.to_f / 1_000_000 if fuel_microliters
        #
        #     # 💨 Conversion en CO₂ (essence : 2.31 kg CO₂ / litre)
        #     co2_kg = fuel_liters ? (fuel_liters * 2.31) : nil
        #
        #     @routes_info << "Adhérent slug = #{intervention[:adherent_slug]}, Distance = #{(response["routes"].first["distanceMeters"].to_f/1000).round(2)} km , Durée = #{(response["routes"].first["duration"].to_f/60).round(2)} min, MicroLitreEssence = #{(response["routes"].first["travelAdvisory"]["fuelConsumptionMicroliters"]).to_f.round(2)}, CO2 = #{co2_kg.round(2)}kg "
        #     @response = response
        #   end
        # end
      end
    end
  end

  def services_for_adherent
    adherent = User.find(params[:adherent_id])
    @services = adherent.services.where(id: current_user.service_ids)

    # On renvoie uniquement l'id et le nom pour construire le <select>
    render json: @services.select(:id, :nom)
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
      @tags = current_user.organisation.interventions.tag_counts_on(:tags).order(:name)
      @adhérents = current_user.organisation.users.filter_by_service(current_user.services).adhérent.order(:nom)
      @services = current_user.services.ordered
      @grouped_agents = User.grouped_agents(current_user)
      @tools = current_user.organisation.tools.ordered
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

    # Ajoute ou enlève l'état 'pointage activé' selon si c'est un modèle de pointage.
    def check_workflow_pointage_mère
      if !@intervention.repeter? && @intervention.workflow_state == 'pointage activé'
        @intervention.workflow_state = 'nouveau'
      elsif @intervention.repeter? && @intervention.workflow_state != 'pointage activé'
        @intervention.workflow_state = 'pointage activé'
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
