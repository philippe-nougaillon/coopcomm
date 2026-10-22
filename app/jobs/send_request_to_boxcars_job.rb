class SendRequestToBoxcarsJob < ApplicationJob
  queue_as :default

  def perform(user_sender, request_message)
    stream = "chat_#{user_sender.id}_with_#{ENV["UUID_AIBOT"]}"

    # Ajoute un message d'attente pour prévenir l'utilisateur que AIBOT réfléchit
    Turbo::StreamsChannel.broadcast_append_to(
      stream,
      partial: 'messagerie/waiting_message',
      target: 'chat-messages-container'
    )

    response_boxcars = {}
    success = true
    
    # Si le debug AÏBBO est activé, on créé un logger pour Boxcars
    if ENV["DEBUG_AIBOT"] == "true"
      loggerBoxcars = LoggerBoxcars.new
    end

    begin
      # Récupération de la réponse de Boxcars
      response_boxcars = FetchBoxcarsInfos.new.call(user_sender, request_message.message)

      response_message = Message.create!(message: response_boxcars[:response], from_id: ENV["UUID_AIBOT"], to_id: user_sender.id)
    rescue StandardError => e
      # Si erreur de boxcars ou du message, cela créé un message d'erreur et l'inscrit dans le log de Boxcars
      response_message = Message.create!(message: "Un problème est survenue avec AÏBBO, veuillez attendre quelques instants et rééssayez.", from_id: ENV["UUID_AIBOT"], to_id: user_sender.id, created_at: DateTime.now)
      loggerBoxcars.add_error_log(e.full_message) if ENV["DEBUG_AIBOT"] == "true"
      success = false
    end

    if ENV["DEBUG_AIBOT"] == "true"
      aibot_log = AibotLog.create!(user: user_sender, request_message: request_message, response_message: response_message, success: success, log_stream: loggerBoxcars.call)
      
      # Envoie du mail sur le log AÏBBO créé
      Events.instance.publish('aibbo.request', payload: { aibot_log_id: aibot_log.id }) if Rails.env.production?
    end
  ensure
    # Enlève le message d'attente dans tous les cas
    Turbo::StreamsChannel.broadcast_remove_to(stream, target: 'waiting_message')
  end
end
