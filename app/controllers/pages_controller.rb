# frozen_string_literal: true

# Handles public and authenticated pages for the application.
class PagesController < ApplicationController
  # Pages publiques (vitrine) : pas d'utilisateur, donc pas d'authorize
  skip_after_action :verify_authorized, only: %i[welcome mentions_legales solution tarifs contact aide]

  before_action :is_user_authorized, except: %i[welcome mentions_legales solution tarifs contact aide]
  skip_before_action :authenticate_user!, only: %i[welcome mentions_legales solution tarifs contact aide]

  layout :define_layout

  def define_layout
    if params[:action] == 'welcome'
      'welcome'
    else
      'application'
    end
  end

  def assistant
    return unless params[:commit].present?

    minimum = 10
    interventions = current_organisation
                    .interventions
                    .where.not(début_prévue: nil)
                    .where(template_slug: nil)
                    .order(:début_prévue)

    if interventions.count >= minimum
      description_list = interventions.map do |i|
        "#{i.description.gsub('[mail] ', '')} #{l(i.début_prévue.to_date)}"
      end

      begin
        llm = Langchain::LLM::MistralAI.new(api_key: ENV['MISTRAL_AI_API_KEY'])
        @results = llm.chat(messages: [{ role: 'user',
                                         content: "Génère moi des nouvelles tâches en te basant sur cette liste : #{description_list.join(', ')}" }]).chat_completion
        # filter_html : la sortie du LLM est influençable par les descriptions
        # d'interventions (injection de prompt) — jamais de HTML brut depuis le LLM.
        @results = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(filter_html: true, safe_links_only: true), {}).render(@results)
      rescue StandardError
        @is_failed = true
        @results = 'Veuillez attendre quelques secondes avant de réessayer'
      end
    else
      @results = "Oups ! Il n'y a pas encore assez d'interventions passées pour générer une proposition fiable.\n Il en faudrait un minimum de #{minimum} pour commencer..."
    end
  end

  def mentions_legales; end

  def aide; end

  def welcome
    @newsletter = Newsletter.new
  end

  def solution; end

  def tarifs; end

  def contact; end

  def home
    hour = Time.now.hour

    base_hour = if hour < 7 || hour > 19
                  20
                else
                  ((hour / 2) * 2).clamp(8, 18)
                end

    @banner_image_name = "banner/banner_#{base_hour}h.jpg"
    @banner_background_color = BACKGROUND_COLORS[base_hour]

    @interventions = Intervention
                     .filter_by_service(current_user.services)
                     .by_role_for_home(current_user)
                     .includes(:service, :organisation)
                     .first(2)

    @messages = current_user.messages
                            .where(read_at: nil)
                            .joins(:from_user)
                            .ordered
                            .first(3)

    @annonces = Message.annonces_pour(current_user).ordered.first(3)

    if current_user.adhérent?
      @cotations = current_user.cotations_adherent.where(workflow_state: Cotation::ENVOYE)
    end

    @conventions = ConventionsDeLAnnee.call(current_user) if policy(Convention).index?
    @forecasts = MeteoConceptConnexion.call
  end

  def meteo
    @forecasts = MeteoConceptConnexion.call
  end

  def meteo_by_day
    forecasts = MeteoConceptConnexion.call
    return render json: {} if forecasts.blank? || forecasts['forecast'].blank?

    day = forecasts['forecast'][params[:day].to_i]
    return render json: {} if day.blank?

    forecast = day.third
    render json: { forecast: forecast, weather: MeteoConceptConnexion.WEATHER[forecast['weather']] }
  end

  private

  def is_user_authorized
    authorize :pages
  end
end
