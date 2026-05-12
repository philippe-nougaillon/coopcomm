class MessagerieController < ApplicationController
  before_action :is_user_authorized

  def index
    # On récupère les utilisateurs avec qui on peut envoyer des messages
    @users = User.by_service(current_user.services).where.not(id: current_user.id).ordered

    @to_user = User.find_by(id: params[:to_id])

    if @to_user
      # On récupère les messages envoyées et reçues d'un utilisateur
      @messages = Message
                        .where(from_id: current_user.id, to_id: @to_user&.id)
                        .or(Message.where(from_id: @to_user&.id, to_id: current_user.id))
                        .order(:created_at)

      unread_messages = @messages.select { |n| n.to_id == current_user.id && n.read_at.nil? }
      
      @unread_count = unread_messages.count
      @first_unread_id = unread_messages.first&.id
    else
      recent_messages = Message.where(from_id: current_user.id)
                                       .or(Message.where(to_id: current_user.id))
                                       .order(created_at: :desc)
      @last_messages = {}
      ordered_user_ids = []
      

      recent_messages.each do |notif|
        other_user_id = notif.from_id == current_user.id ? notif.to_id : notif.from_id
        
        unless @last_messages.key?(other_user_id)
          @last_messages[other_user_id] = notif
          ordered_user_ids << other_user_id
        end
      end

      users_by_id = User.where(id: ordered_user_ids).index_by(&:id)

      @recent_conversations = ordered_user_ids.map { |id| users_by_id[id] }.compact
      @unread_counts = Message.where(to_id: current_user.id, read_at: nil).group(:from_id).count
    end
  end

  def send_message
    if params[:message].present? && params[:to_id].present?
      Message.create!(message: params[:message], from_id: current_user.id, to_id: params[:to_id])
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
    @users = User.by_service(current_user.services).where.not(id: current_user.id).where("users.nom ILIKE :search OR users.prénom ILIKE :search", { search: "%#{params[:query]}%"}).ordered
    render partial: 'users_list', locals: { users: @users }
  end

  private

  def is_user_authorized
    authorize :messagerie
  end

end
