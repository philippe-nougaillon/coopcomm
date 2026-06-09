class PagesController < ApplicationController
  before_action :is_user_authorized, except: %i[welcome mentions_legales solution tarifs contact]
  skip_before_action :authenticate_user!, only: %i[welcome mentions_legales solution tarifs contact]

  layout :define_layout

  def define_layout
    if params[:action] == 'welcome'
      'welcome'
    else
      'application'
    end
  end

  def assistant
    if params[:commit].present?
      minimum = 10
      interventions = current_organisation
                        .interventions
                        .where.not(début_prévue: nil)
                        .where(template_slug: nil)
                        .order(:début_prévue)

      if interventions.count >= minimum
        description_list = []
        interventions.each do |intervention|
          description_list << "#{intervention.description.gsub('[mail] ', '')} #{l(intervention.début_prévue.to_date)}"
        end

        # Version Mistral
        begin
          llm = Langchain::LLM::MistralAI.new(api_key: ENV["MISTRAL_AI_API_KEY"])
          @results = llm.chat(messages: [{role: "user", content: "Génère moi des nouvelles tâches en te basant sur cette liste : #{description_list.join(', ')}"}]).chat_completion
          markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})
          @results = markdown.render(@results)
        rescue
          @is_failed = true
          @results = "Veuillez attendre quelques secondes avant de réessayer"
        end
      else
        @results = "Oups ! Il n'y a pas encore assez d'interventions passées pour générer une proposition fiable.\n Il en faudrait un minimum de #{ minimum } pour commencer..."
      end
    end
  end

  def mentions_legales
  end

  def welcome
    @wiki_pages = WikiPage.where(publiée: true)
    @newsletter = Newsletter.new
  end

  def dashboard
    start_date = 9.months.ago.beginning_of_month
    end_date = 3.months.from_now.end_of_month
    
    if current_user.manager_or_admin?
      @export_logs = current_organisation.export_logs.includes(:user).order(created_at: :desc)
      users = User.by_service(current_user.services)

      # Temps total par adhérent
      @temps_total_par_adhérent = {}
      users.adhérent.includes(:interventions_adherent).each do |adhérent|
        @temps_total_par_adhérent[adhérent.nom_prénom] = adhérent.interventions_adherent.to_a.sum(&:temps_total)
      end

      # Temps total par agent
      @temps_total_par_agent = {}
      users.agent.includes(:agent_interventions, :interventions).each do |agent|
        @temps_total_par_agent[agent.nom_prénom] = 0
        agent.interventions.each do |intervention|
          @temps_total_par_agent[agent.nom_prénom] += intervention.temps_total / intervention.agents.size
        end
      end

      # Graphe Quantité d'interventions par état et par mois
      qté_interventions_par_mois_par_état = {}
      current_organisation.interventions.filter_by_service(current_user.services).where(début: start_date..end_date).group("DATE_TRUNC('month', début)", :workflow_state).count.each do |(month, state), count|
        formatted_month = month.to_date.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        qté_interventions_par_mois_par_état[formatted_month][state] = count
      end

      workflows = [Intervention::NOUVEAU, Intervention::POINTAGE_ACTIVE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]
      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        workflows.each do |state|
          qté_interventions_par_mois_par_état[formatted_month][state] ||= 0
        end
      end

      qté_interventions_par_mois_par_état = qté_interventions_par_mois_par_état.sort.to_h
      labels = qté_interventions_par_mois_par_état.keys

      datasets = workflows.map do |workflow|
        {
          label: workflow.capitalize,
          data: labels.map { |month| qté_interventions_par_mois_par_état[month][workflow] },
          backgroundColor: case workflow
                          when Intervention::NOUVEAU then "rgba(0,181,255,255)"
                          when Intervention::POINTAGE_ACTIVE then "rgba(123,146,178,255)"
                          when Intervention::TERMINE then "rgba(77,110,255,255)"
                          when Intervention::VALIDE then "rgba(0,169,110,255)"
                          when Intervention::REFUSE then "rgba(255,88,97,255)"
                          when Intervention::ARCHIVE then "rgba(232,232,232,255)"
                          end
        }
      end
      @data_workflow_chart = { labels: labels, datasets: datasets }

      # Graphe qté d'intervention par service
      @qté_interventions_par_service = current_organisation.interventions.filter_by_service(current_user.services).joins(:service).group("services.nom").count

      # Graphe temps_total par service
      @temps_total_par_service = current_organisation.interventions.filter_by_service(current_user.services).joins(:service).group("services.nom").sum(:temps_total)

      # Graphe co2 total par mois
      co2_total_par_mois = {}
      current_organisation.interventions.filter_by_service(current_user.services).where(début: start_date..end_date).group("DATE_TRUNC('month', début)").sum(:co2).each do |month, co2|
        formatted_month = month.to_date.strftime('%Y-%m')
        co2_total_par_mois[formatted_month] = co2
      end

      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        co2_total_par_mois[formatted_month] ||= 0
      end
      @co2_total_par_mois = co2_total_par_mois.sort.to_h

      # =================================================================
      # NUEVOS KPIs: ÁREA MANAGER/ADMIN (Datos globales de organización)
      # =================================================================
      manager_interventions = current_organisation.interventions.filter_by_service(current_user.services)
      @kpi_total_interventions = manager_interventions.count
      @kpi_temps_total         = "#{manager_interventions.sum(:temps_total).round(1)}h"
      @kpi_agents_actifs       = users.agent.count
      @kpi_co2_total           = "#{@co2_total_par_mois.values.sum.round(1)} kg"

    elsif current_user.adhérent?
      user_interventions = current_user.interventions_adherent.filter_by_service(current_user.services)
      temps_consommable_adhérent_mensuellement = 100

      # Graphe temps consommé
      @proportion_temps_consommé = {}
      @proportion_temps_consommé["temps_consommé"] = user_interventions.sum(:temps_total)
      @proportion_temps_consommé["temps_restant"] = temps_consommable_adhérent_mensuellement - user_interventions.sum(:temps_total)

      # Graphe temps_total par mois
      @temps_total_par_mois = {}
      user_interventions.where(début: start_date..end_date).group("DATE_TRUNC('month', début)").sum(:temps_total).each do |month, total|
        formatted_month = month.to_date.strftime('%Y-%m')
        @temps_total_par_mois[formatted_month] = total
      end

      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        @temps_total_par_mois[formatted_month] ||= 0.0
      end
      @temps_total_par_mois = @temps_total_par_mois.sort.to_h

      # Graphe Quantité d'interventions par estado et par mois
      qté_interventions_par_mois_par_état = {}
      user_interventions.where(début: start_date..end_date).group("DATE_TRUNC('month', début)", :workflow_state).count.each do |(month, state), count|
        formatted_month = month.to_date.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        qté_interventions_par_mois_par_état[formatted_month][state] = count
      end

      workflows = [Intervention::NOUVEAU, Intervention::POINTAGE_ACTIVE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]
      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        workflows.each do |state|
          qté_interventions_par_mois_par_état[formatted_month][state] ||= 0
        end
      end

      qté_interventions_par_mois_par_état = qté_interventions_par_mois_par_état.sort.to_h
      labels = qté_interventions_par_mois_par_état.keys

      datasets = workflows.map do |workflow|
        {
          label: workflow.capitalize,
          data: labels.map { |month| qté_interventions_par_mois_par_état[month][workflow] },
          backgroundColor: case workflow
                          when Intervention::NOUVEAU then "rgba(0,181,255,255)"
                          when Intervention::POINTAGE_ACTIVE then "rgba(123,146,178,255)"
                          when Intervention::TERMINE then "rgba(77,110,255,255)"
                          when Intervention::VALIDE then "rgba(0,169,110,255)"
                          when Intervention::REFUSE then "rgba(255,88,97,255)"
                          when Intervention::ARCHIVE then "rgba(232,232,232,255)"
                          end
        }
      end
      @data_workflow_chart = { labels: labels, datasets: datasets }

      # Graphe qté d'intervention par service
      @qté_interventions_par_service = user_interventions.joins(:service).group("services.nom").count

      # Graphe temps_total par service
      @temps_total_par_service = user_interventions.joins(:service).group("services.nom").sum(:temps_total)

      # Graphe co2 total par mois
      co2_total_par_mois = {}
      user_interventions.where(début: start_date..end_date).group("DATE_TRUNC('month', début)").sum(:co2).each do |month, co2|
        formatted_month = month.to_date.strftime('%Y-%m')
        co2_total_par_mois[formatted_month] = co2
      end

      (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        co2_total_par_mois[formatted_month] ||= 0
      end
      @co2_total_par_mois = co2_total_par_mois.sort.to_h

      # =================================================================
      # NUEVOS KPIs: ÁREA ADHÉRENT (Datos específicos de este usuario)
      # =================================================================
      @kpi_total_interventions = user_interventions.count
      @kpi_temps_total         = "#{@proportion_temps_consommé['temps_consommé'].round(1)}h"
      @kpi_agents_actifs       = current_organisation.users.agent.by_service(current_user.services).count rescue 0
      @kpi_co2_total           = "#{@co2_total_par_mois.values.sum.round(1)} kg"
    end

    respond_to do |format|
      format.html {}
      format.xls do
        if current_user.manager_or_admin?
          xls_file = DashboardManagerToXls.new(@temps_total_par_adhérent, @temps_total_par_agent, @data_workflow_chart, @qté_interventions_par_service, @temps_total_par_service, @co2_total_par_mois).call
          ExportLog.create!(user: current_user, organisation: current_organisation, export_type: 'dashboard_manager')
        else
          xls_file = DashboardAdherentToXls.new(@proportion_temps_consommé, @temps_total_par_mois, @data_workflow_chart, @qté_interventions_par_service, @temps_total_par_service, @co2_total_par_mois).call
          ExportLog.create!(user: current_user, organisation: current_organisation, export_type: 'dashboard_adherent')
        end
        send_data xls_file, filename: "Dashboard_#{l Date.today}.xls"
      end
    end
  end

  def solution
  end

  def tarifs
  end

  def contact
  end

  def home
    hour = Time.now.hour

    if hour < 7 || hour > 19
      base_hour = 20
    else
      base_hour = ((hour / 2) * 2).clamp(8, 18)
    end

    @banner_image_name = "banner/banner_#{base_hour}h.png"
    @banner_background_color = BACKGROUND_COLORS[base_hour]

    @interventions = Intervention
                       .filter_by_service(current_user.services)
                       .by_role_for_home(current_user)
                       .first(2)

    @messages = current_user.messages
                            .where(read_at: nil)
                            .joins(:from_user)
                            .ordered
                            .first(3)

    @forecasts = MeteoConceptConnexion.call
  end

  def meteo
    @forecasts = MeteoConceptConnexion.call
  end

  def meteo_by_day
    forecasts = MeteoConceptConnexion.call
    forecast = forecasts["forecast"][params[:day].to_i].third
    render json: { forecast: forecast, weather: MeteoConceptConnexion.WEATHER[forecast["weather"]] }
  end

  private

  def is_user_authorized
    authorize :pages
  end
end

