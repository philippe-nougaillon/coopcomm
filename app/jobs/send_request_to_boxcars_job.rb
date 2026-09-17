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
    succes = true

    begin # Récupération de la réponse de Boxcars
      response_boxcars = FetchBoxcarsInfos.new.call(user_sender, request_message.message)
      raise "Échec de l'appel à Boxcars" if response_boxcars[:succes] == false

      response_message = Message.create!(message: response_boxcars[:response], from_id: ENV["UUID_AIBOT"], to_id: user_sender.id)
    rescue # Si erreur, cela créé un message d'erreur
      succes = false
      response_message = Message.create!(message: "Un problème est survenue avec AIBOT, veuillez attendre quelques instants et rééssayez.", from_id: ENV["UUID_AIBOT"], to_id: user_sender.id, created_at: DateTime.now)
    ensure # Enlève le message d'attente dans tous les cas
      Turbo::StreamsChannel.broadcast_remove_to(stream, target: 'waiting_message')
    end

    if ENV["DEBUG_AIBOT"] == "true"
      AibotLog.create!(user: user_sender, request_message: request_message, response_message: response_message, succes: succes, log_stream: response_boxcars[:log_stream])
    end
  end
end
