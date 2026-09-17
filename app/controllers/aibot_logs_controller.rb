# frozen_string_literal: true

class AibotLogsController < ApplicationController
  before_action :set_aibot_log, only: %i[show]
  before_action :is_user_authorized

  def index
    @users = User.with_discarded.where(id: AibotLog.select(:user_id)).ordered
    @aibot_logs = AibotLog.ordered.includes(:user, :request_message)

    if params[:search].present?
      messages = Message.where('messages.message ILIKE ?', "%#{params[:search]}%")
      @aibot_logs = @aibot_logs.where(request_message_id: messages).or(@aibot_logs.where(response_message_id: messages))
    end

    @aibot_logs = @aibot_logs.where(user_id: params[:user_id]) if params[:user_id].present?
    @aibot_logs = @aibot_logs.where(succes: false) if params[:ko].present?

    @pagy, @aibot_logs = pagy(@aibot_logs)
  end

  def show; end

  private

  def set_aibot_log
    @aibot_log = AibotLog.find_by(slug: params[:id])
    return unless @aibot_log.nil?

    redirect_to root_path, alert: 'Aibot log introuvable'
  end

  def is_user_authorized
    authorize @aibot_log || AibotLog
  end
end
