# frozen_string_literal: true

class LoggerBoxcars < ApplicationService
  
  # Création d'un logger pour que Boxcars écrivent les logs dessus
  # Nécessaire à chaque call pour récupérer les logs juste pour cet appel 
  def initialize
    @log_stream = StringIO.new
    @origin_logger = Boxcars.configuration.logger

    Boxcars.configuration.logger = ActiveSupport::BroadcastLogger.new(
      ActiveSupport::TaggedLogging.new(Logger.new(@log_stream)).tagged("AÏBBO"), 
      @origin_logger
    )
  end

  def call
    # Réattribution du logger Boxcars à celui de base
    Boxcars.configuration.logger = @origin_logger

    # Retourne le log écrit dans le stream
    return @log_stream.string
  end

  # Renvoie dans le logger Boxcars l'erreur de l'exception
  def add_error_log(message)
    Boxcars.configuration.logger.error(message)
  end
end