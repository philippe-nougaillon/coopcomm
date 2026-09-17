# frozen_string_literal: true

class MessagerieController < ApplicationController
  before_action :is_user_authorized
  before_action :set_sidebar_users, only: %i[index conversation]


  # Accueil de la messagerie : liste des discussions récentes (sans interlocuteur sélectionné)
  def index
    recent_messages = Message
                      .where(from_id: current_user.id)
                      .or(Message.where(to_id: current_user.id))
                      .where.not(from_id: ENV["UUID_AIBOT"])
                      .where.not(to_id: ENV["UUID_AIBOT"])
                      .order(created_at: :desc)

    @last_messages = {}
    ordered_user_ids = []

    recent_messages.each do |notif|
      # Détermine qui est l'interlocuteur avec l'utilisateur courant
      interlocutor_id = notif.from_id == current_user.id ? notif.to_id : notif.from_id

      unless @last_messages.key?(interlocutor_id)
        @last_messages[interlocutor_id] = notif
        ordered_user_ids << interlocutor_id
      end
    end

    users_by_id = User
                  .where(id: ordered_user_ids)
                  .with_attached_profile_picture
                  .index_by(&:id)

    @recent_conversations = ordered_user_ids.map { |id| users_by_id[id] }.compact

    # Compte les messages non lus envoyés par chaque utilisateur à l'utilisateur actuel
    @unread_counts = Message.where(to_id: current_user.id, read_at: nil).group(:from_id).count
  end

  # Conversation avec un interlocuteur donné
  def conversation
    @destinataire = joinables_et_aibot.find_by(slug: params[:to_user_slug])

    # Interlocuteur inexistant ou soi-même → retour à l'accueil de la messagerie
    return redirect_to(messagerie_path) if @destinataire.nil? || @destinataire.id == current_user.id

    # On récupère les messages envoyés et reçus avec cet interlocuteur
    @messages = Message
                .where(from_id: current_user.id, to_id: @destinataire.id)
                .or(Message.where(from_id: @destinataire.id, to_id: current_user.id))
                .order(:created_at)

    # Message de bienvenue d'aibot pour la première fois
    if @messages.empty? && @destinataire.is_aibot?
      Message.create(message: "Bonjour #{current_user.nom_prénom}, je m'appelle AIBOT. Comment puis-je vous aider ? \n Vous pouvez me posez des questions comme; 'Combien j'ai d'interventions dans la journée ?' " ,from_id: ENV["UUID_AIBOT"], to_id: current_user.id)
    end

    unread_messages = @messages.select { |n| n.to_id == current_user.id && n.read_at.nil? }

    @unread_count = unread_messages.count
    @first_unread_id = unread_messages.first&.id
  end

  def send_message
    # Evite que l'utilisateur courant envoie un message à lui-même
    return unless params[:message].present? && params[:to_user_slug].present? && (params[:to_user_slug] != current_user.slug)

    # Le destinataire doit être joignable (to_id forgeable : inter-organisations sinon)
    destinataire = joinables_et_aibot.find_by(slug: params[:to_user_slug])
    return if destinataire.nil?

    message = Message.create!(message: params[:message], from_id: current_user.id, to_id: destinataire.id)
    
    if message.valid?
      if destinataire.is_aibot?
        stream = "chat_#{current_user.id}_with_#{ENV["UUID_AIBOT"]}"

        Turbo::StreamsChannel.broadcast_append_to(
          stream,
          partial: 'messagerie/waiting_message',
          target: 'chat-messages-container'
        )

        begin
          response = FetchBoxcarsInfos.new.call(current_user, params[:message])
          Message.create!(message: response[:response], from_id: ENV["UUID_AIBOT"], to_id: current_user.id)
        ensure
          Turbo::StreamsChannel.broadcast_remove_to(stream, target: 'waiting_message')
        end

        if ENV["DEBUG_AIBOT"] == "true"
          Message.create!(message: response[:log_stream], from_id: ENV["UUID_AIBOT"], to_id: current_user.id)
        end
      end

      head :created
    else
      head :bad_request
    end
  end

  def mark_as_read
    message = Message.find(params[:id])

    # Sécurité : on vérifie que c'est bien un message destiné à l'utilisateur courant
    if message.to_id == current_user.id && message.read_at.nil?
      message.update(read_at: Time.current)

      # Plus tard, on pourra ajouter un Turbo Stream ici pour mettre à jour
      # les fameux "deux traits bleus" chez l'expéditeur !
    end

    head :ok # Renvoie juste un statut 200 (OK) sans recharger de page
  end

  def search_contact
    @users = joignables
             .where.not(id: current_user.id)
             .ordered

    if params[:query].present?
      @users = @users.where('users.nom ILIKE :search OR users.prénom ILIKE :search', { search: "%#{params[:query]}%" })
    end

    @users = @users.with_attached_profile_picture

    render partial: 'users_list', locals: { users: @users }
  end

  private

  # Renvoie les utilisateurs joignables (du même service)
  def joignables
    User.by_service(current_user.services)
  end

  def joinables_et_aibot
    joignables.or(User.where(id: ENV["UUID_AIBOT"]))
  end

  # Utilisateurs joignables, affichés dans la sidebar des contacts de la messagerie
  def set_sidebar_users
    @users = joignables
             .where.not(id: current_user.id)
             .ordered
             .with_attached_profile_picture
  end

  def is_user_authorized
    authorize :messagerie
  end
end
