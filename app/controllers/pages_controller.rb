class PagesController < ApplicationController
  before_action :is_user_authorized, except: %i[mentions_legales]
  skip_before_action :authenticate_user!, only: %i[mentions_legales]
  
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

  private

  def is_user_authorized
    authorize :pages
  end
end