# frozen_string_literal: true

# [{ user:, last_message:, unread_count: }] : un interlocuteur actif et joignable par discussion, la plus récente en tête,
# son dernier message échangé dans un sens ou dans l'autre et ceux qu'il a envoyés sans qu'ils soient lus.
class DiscussionsRecentes < ApplicationService
  def initialize(user)
    @user = user
  end

  def call
    derniers_messages = Message.where(id: dernier_message_par_interlocuteur).ordered
    interlocuteurs = User
                     .by_service(@user.services)
                     .where(id: derniers_messages.map { |message| interlocuteur_id(message) })
                     .with_attached_profile_picture
                     .index_by(&:id)
    non_lus = Message.message.where(to_id: @user.id, read_at: nil).group(:from_id).count

    derniers_messages.filter_map do |message|
      interlocuteur = interlocuteurs[interlocuteur_id(message)]
      { user: interlocuteur, last_message: message, unread_count: non_lus.fetch(interlocuteur.id, 0) } if interlocuteur
    end
  end

  private

  def dernier_message_par_interlocuteur
    interlocuteur = Message.sanitize_sql_array(['CASE WHEN messages.from_id = ? THEN messages.to_id ELSE messages.from_id END', @user.id])

    Message
      .where(from_id: @user.id)
      .or(Message.where(to_id: @user.id))
      .message
      .select(Arel.sql("DISTINCT ON (#{interlocuteur}) messages.id"))
      .order(Arel.sql(interlocuteur), created_at: :desc)
  end

  def interlocuteur_id(message)
    message.from_id == @user.id ? message.to_id : message.from_id
  end
end
