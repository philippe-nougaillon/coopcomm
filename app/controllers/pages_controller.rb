class PagesController < ApplicationController
  before_action :is_user_authorized, except: %i[welcome mentions_legales]
  skip_before_action :authenticate_user!, only: %i[welcome mentions_legales]

  def assistant

    if params[:commit].present?
      minimum = 10
      interventions = current_user.organisation
                                  .interventions
                                  .where.not(début: nil)
                                  .order(:début)

      if interventions.count >= minimum
        description_list = []
        interventions.each do |intervention|
          description_list << "#{intervention.description.gsub('[mail] ', '')} #{l(intervention.début.to_date)}"
        end

        llm = Langchain::LLM::OpenAI.new(api_key: ENV["OPENAI_API_KEY"])
        @results = llm.chat(messages: [{role: "user", content: "Génère moi des nouvelles tâches en te basant sur cette liste : #{description_list.join(', ')}"}]).completion
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
    if current_user.manager?
      # temps_consommable_agent_mensuellement = 35 * 4
      # temps_consommable_organisation_mensuellement = current_user.organisation.users.adherent.count * 100
      #
      # Temps total par adhérent
      #
      @temps_total_par_adhérent = {}
      current_user.organisation.users.adhérent.each do |adhérent|
        @temps_total_par_adhérent[adhérent.nom_prénom] = adhérent.interventions_adherent.sum(:temps_total)
      end

      #
      # Temps total par agent
      #

      @temps_total_par_agent = {}
      current_user.organisation.users.agent.each do |agent|
        @temps_total_par_agent[agent.nom_prénom] = 0
        agent.interventions.each do |intervention|
          @temps_total_par_agent[agent.nom_prénom] += intervention.temps_total / intervention.agents.count
        end
      end

      #
      # Graphe Quantité d'interventions par état et par mois
      #

      qté_interventions_par_mois_par_état = {}

      current_user.organisation.interventions.where(début: start_date..end_date).group("DATE_TRUNC('month', début)", :workflow_state).count.each do |(month, state), count|
        formatted_month = month.to_date.strftime('%Y-%m') # Format: "YYYY-MM"
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        qté_interventions_par_mois_par_état[formatted_month][state] = count
      end

      # Compléter les mois et workflows manquants avec des valeurs par défaut
      workflows = [Intervention::NOUVEAU, Intervention::ATTENTE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]

      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        workflows.each do |state|
          qté_interventions_par_mois_par_état[formatted_month][state] ||= 0
        end
      end

      qté_interventions_par_mois_par_état = qté_interventions_par_mois_par_état.sort.to_h # Trier par ordre chronologique

      labels = qté_interventions_par_mois_par_état.keys # Les mois comme étiquettes pour l'axe X
      workflows = [Intervention::NOUVEAU, Intervention::ATTENTE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]

      datasets = workflows.map do |workflow|
        {
          label: workflow.capitalize, # Nom de l'état de workflow
          data: labels.map { |month| qté_interventions_par_mois_par_état[month][workflow] }, # Quantités par mois
          backgroundColor: case workflow
                          when Intervention::NOUVEAU then "rgba(0,181,255,255)" # Info
                          when Intervention::ATTENTE then "rgba(123,146,178,255)" # Secondary
                          when Intervention::TERMINE then "rgba(77,110,255,255)" # Primary
                          when Intervention::VALIDE then "rgba(0,169,110,255)" # Success
                          when Intervention::REFUSE then "rgba(255,88,97,255)" # Error
                          when Intervention::ARCHIVE then "rgba(232,232,232,255)" # Ghost
                          end
        }
      end

      @data_workflow_chart = { labels: labels, datasets: datasets }

      #
      # Graphe qté d'intervention par service
      #

      @qté_interventions_par_service = current_user.organisation.interventions.joins(agent_interventions: :agent).group('users.service').count


      #
      # Graphe temps_total par service
      #

      @temps_total_par_service = {}
      # pour chaque service, faire le sum des temps totaux
      # current_user.interventions_adherent.joins(agent_interventions: :agent).each do |intervention|
      #   @temps_total_par_service
      # end

      @temps_total_par_service = current_user.organisation.interventions.joins(agent_interventions: :agent).group("users.service").sum(:temps_total)

    elsif current_user.adhérent?
      temps_consommable_adhérent_mensuellement = 100

      #
      # Graphe temps consommé
      #

      @proportion_temps_consommé = {}
      @proportion_temps_consommé["temps_consommé"] = current_user.interventions_adherent.sum(:temps_total)
      @proportion_temps_consommé["temps_restant"] = temps_consommable_adhérent_mensuellement - current_user.interventions_adherent.sum(:temps_total)



      #
      # Graphe temps_total par mois
      #

      @temps_total_par_mois = {}

      current_user.interventions_adherent.where(début: start_date..end_date).group("DATE_TRUNC('month', début)").sum(:temps_total).each do |month, total|
        formatted_month = month.to_date.strftime('%Y-%m') # Format: "YYYY-MM"
        @temps_total_par_mois[formatted_month] = total
      end

      # Compléter les mois manquants avec des valeurs par défaut
      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        @temps_total_par_mois[formatted_month] ||= 0.0
      end

      @temps_total_par_mois = @temps_total_par_mois.sort.to_h # Trier par ordre chronologique



      #
      # Graphe Quantité d'interventions par état et par mois
      #

      qté_interventions_par_mois_par_état = {}

      current_user.interventions_adherent.where(début: start_date..end_date).group("DATE_TRUNC('month', début)", :workflow_state).count.each do |(month, state), count|
        formatted_month = month.to_date.strftime('%Y-%m') # Format: "YYYY-MM"
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        qté_interventions_par_mois_par_état[formatted_month][state] = count
      end

      # Compléter les mois et workflows manquants avec des valeurs par défaut
      workflows = [Intervention::NOUVEAU, Intervention::ATTENTE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]

      (start_date.to_date..end_date.to_date).map { |date| date.beginning_of_month }.uniq.each do |month|
        formatted_month = month.strftime('%Y-%m')
        qté_interventions_par_mois_par_état[formatted_month] ||= {}
        workflows.each do |state|
          qté_interventions_par_mois_par_état[formatted_month][state] ||= 0
        end
      end

      qté_interventions_par_mois_par_état = qté_interventions_par_mois_par_état.sort.to_h # Trier par ordre chronologique

      labels = qté_interventions_par_mois_par_état.keys # Les mois comme étiquettes pour l'axe X
      workflows = [Intervention::NOUVEAU, Intervention::ATTENTE, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE]

      datasets = workflows.map do |workflow|
        {
          label: workflow.capitalize, # Nom de l'état de workflow
          data: labels.map { |month| qté_interventions_par_mois_par_état[month][workflow] }, # Quantités par mois
          backgroundColor: case workflow
                          when Intervention::NOUVEAU then "rgba(0,181,255,255)" # Info
                          when Intervention::ATTENTE then "rgba(123,146,178,255)" # Secondary
                          when Intervention::TERMINE then "rgba(77,110,255,255)" # Primary
                          when Intervention::VALIDE then "rgba(0,169,110,255)" # Success
                          when Intervention::REFUSE then "rgba(255,88,97,255)" # Error
                          when Intervention::ARCHIVE then "rgba(232,232,232,255)" # Ghost
                          end
        }
      end

      @data_workflow_chart = { labels: labels, datasets: datasets }


      #
      # Graphe qté d'intervention par service
      #

      @qté_interventions_par_service = current_user.interventions_adherent.joins(agent_interventions: :agent).group("users.service").count


      #
      # Graphe temps_total par service
      #

      @temps_total_par_service = {}
      # pour chaque service, faire le sum des temps totaux
      # current_user.interventions_adherent.joins(agent_interventions: :agent).each do |intervention|
      #   @temps_total_par_service
      # end

      @temps_total_par_service = current_user.interventions_adherent.joins(agent_interventions: :agent).group("users.service").sum(:temps_total)
    end
  end

  private

  def is_user_authorized
    authorize :pages
  end
end