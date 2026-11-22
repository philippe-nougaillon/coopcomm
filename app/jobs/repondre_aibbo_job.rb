class RepondreAibboJob < ApplicationJob
  queue_as :default

  def perform(user_sender, request_message, niveau = nil)
    stream = "chat_#{user_sender.id}_with_#{ENV["UUID_AIBOT"]}"

    # Ajoute un message d'attente pour prévenir l'utilisateur que AIBOT réfléchit
    Turbo::StreamsChannel.broadcast_append_to(
      stream,
      partial: 'messagerie/waiting_message',
      target: 'chat-messages-container'
    )

    reponse = Aibbo::Repondre.call(user_sender, request_message, niveau)
    trace = reponse.trace
    success = true

    # Création du message vers l'utilisateur avec la réponse de AÏBBO
    response_message = Message.create!(message: reponse.texte, from_id: ENV["UUID_AIBOT"], to_id: user_sender.id)

  rescue StandardError => e
    # Si erreur du modèle ou du message, cela créé un message d'erreur
    response_message = Message.create!(message: Aibbo::Repondre::PANNE, from_id: ENV["UUID_AIBOT"], to_id: user_sender.id, created_at: DateTime.now)
    trace = e.full_message(highlight: true)
    success = false
  ensure
    # Enlève le message d'attente dans tous les cas
    Turbo::StreamsChannel.broadcast_remove_to(stream, target: 'waiting_message')

    if ENV["DEBUG_AIBOT"] == "true"
      aibot_log = AibotLog.create!(user: user_sender, request_message: request_message, response_message: response_message, succes: success, log_stream: trace)

      # Envoie du mail sur le log AÏBBO créé
      Events.instance.publish('aibbo.request', payload: { aibot_log_id: aibot_log.id }) if Rails.env.production?
    end
  end
end
