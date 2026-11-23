# frozen_string_literal: true

class MessagerieController < ApplicationController
  before_action :is_user_authorized, except: %i[annonces send_annonce]
  before_action :set_sidebar_users, only: %i[index conversation annonces]
  before_action :set_cible_des_annonces, only: %i[annonces send_annonce]


  # Accueil de la messagerie : liste des discussions récentes (sans interlocuteur sélectionné)
  def index
    @discussions = DiscussionsRecentes.call(current_user)

    dernières_par_service = Message
                            .annonces_pour(current_user)
                            .annonce
                            .select('DISTINCT ON (to_id) id')
                            .order(:to_id, created_at: :desc)
    @annonces = Message.where(id: dernières_par_service).ordered
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
                .message
                .order(:created_at)

    # Message de bienvenue d'aibot pour la première fois
    if @messages.empty? && @destinataire.is_aibot?
      Message.create(message: "Bonjour #{current_user.nom_prénom}, je m'appelle AÏBBO. Je réponds à vos questions sur les interventions que vous pouvez voir dans CoopComm.\nComment puis-je vous aider ?\nVous pouvez me demander par exemple : « Combien d'interventions ont été terminées ce mois-ci ? »", from_id: ENV["UUID_AIBOT"], to_id: current_user.id)
    end

    unread_messages = @messages.select { |n| n.to_id == current_user.id && n.read_at.nil? }

    @unread_count = unread_messages.count
    @first_unread_id = unread_messages.first&.id
    @flux = "chat_#{current_user.id}_with_#{@destinataire.id}"
    @url_envoi = messagerie_send_message_path
    @peut_ecrire = true
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
        session[:niveau_aibbo] = params[:niveau] if Aibbo::Repondre::NIVEAUX.key?(params[:niveau])
        RepondreAibboJob.perform_later(current_user, message, session[:niveau_aibbo])
      end

      head :created
    else
      head :bad_request
    end
  end

  def mark_as_read
    message = Message.find(params[:id])

    # Sécurité : on vérifie que c'est bien un message destiné à l'utilisateur courant
    if message.message? && message.to_id == current_user.id && message.read_at.nil?
      message.update(read_at: Time.current)

      # Plus tard, on pourra ajouter un Turbo Stream ici pour mettre à jour
      # les fameux "deux traits bleus" chez l'expéditeur !
    end

    head :ok # Renvoie juste un statut 200 (OK) sans recharger de page
  end

  def search_contact
    @users = joignables
             .where.not(id: current_user.id)
             .order(conversation_la_plus_récente_en_tête)
             .ordered

    if params[:query].present?
      @users = @users.where('users.nom ILIKE :search OR users.prénom ILIKE :search', { search: "%#{params[:query]}%" })
    end

    @users = @users.with_attached_profile_picture

    render partial: 'users_list', locals: { users: @users, non_lus: current_user.messages_non_lus.group(:from_id).count }
  end

  # Annonces d'un service, ou générales à l'organisation sans slug de service ; même page que la conversation
  def annonces
    authorize @cible, :annonces?, policy_class: MessageriePolicy

    @messages = Message.annonces_de(@cible).order(:created_at)
    @titre = @cible.is_a?(Service) ? "Annonces · #{@cible.nom}" : 'Tout le monde'
    @flux = Message.flux_annonces(@cible)
    @url_envoi = messagerie_send_annonce_path
    @peut_ecrire = MessageriePolicy.new(current_user, @cible).send_annonce?

    render :conversation
  end

  def send_annonce
    authorize @cible, :send_annonce?, policy_class: MessageriePolicy
    return if params[:message].blank?

    Message.annonces_de(@cible).create!(message: params[:message], from_id: current_user.id)
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
             .order(conversation_la_plus_récente_en_tête)
             .ordered
             .with_attached_profile_picture

    @services_annonces = current_user.get_services_by_role unless current_user.adhérent?
  end

  def is_user_authorized
    authorize :messagerie
  end

  # Le service dont le slug est donné, sinon l'organisation entière ; introuvable → accueil de la messagerie
  def set_cible_des_annonces
    @cible = params[:service_slug].blank? ? current_organisation : current_organisation.services.find_by(slug: params[:service_slug])

    redirect_to messagerie_path if @cible.nil?
  end

  def conversation_la_plus_récente_en_tête
    dernier_message = Message.message
                             .where('(messages.from_id = users.id AND messages.to_id = :moi) OR (messages.from_id = :moi AND messages.to_id = users.id)',
                                    moi: current_user.id)
                             .select('MAX(messages.created_at)')

    Arel.sql("(#{dernier_message.to_sql}) DESC NULLS LAST")
  end
end
