# frozen_string_literal: true

class MailLogsController < ApplicationController
  before_action :set_mail_log, only: %i[show]
  before_action :is_user_authorized

  # GET /mail_logs or /mail_logs.json
  def index
    @organisation_mail_logs = current_organisation.mail_logs
    @mail_logs = @organisation_mail_logs.ordered

    @emails = User.by_service(current_user.services).pluck(:email).sort

    unless params[:search].blank?
      @mail_logs = @mail_logs.where('LOWER(mail_logs.to) like :search', { search: "%#{params[:search]}%".downcase })
    end

    @mail_logs = @mail_logs.where(subject: params[:search_subject]) unless params[:search_subject].blank?

    @mail_logs = @mail_logs.where(statut: false) if params[:ko].present?

    @pagy, @mail_logs = pagy(@mail_logs)
  end

  # GET /mail_logs/1 or /mail_logs/1.json
  def show; end

  # # GET /mail_logs/new
  # def new
  #   @mail_log = MailLog.new
  # end
  #
  # # GET /mail_logs/1/edit
  # def edit
  # end
  #
  # # POST /mail_logs or /mail_logs.json
  # def create
  #   @mail_log = MailLog.new(mail_log_params)
  #
  #   respond_to do |format|
  #     if @mail_log.save
  #       format.html { redirect_to mail_log_url(@mail_log), notice: "Mail log was successfully created." }
  #       format.json { render :show, status: :created, location: @mail_log }
  #     else
  #       format.html { render :new, status: :unprocessable_content }
  #       format.json { render json: @mail_log.errors, status: :unprocessable_content }
  #     end
  #   end
  # end
  #
  # # PATCH/PUT /mail_logs/1 or /mail_logs/1.json
  # def update
  #   respond_to do |format|
  #     if @mail_log.update(mail_log_params)
  #       format.html { redirect_to mail_log_url(@mail_log), notice: "Mail log was successfully updated." }
  #       format.json { render :show, status: :ok, location: @mail_log }
  #     else
  #       format.html { render :edit, status: :unprocessable_content }
  #       format.json { render json: @mail_log.errors, status: :unprocessable_content }
  #     end
  #   end
  # end
  #
  # # DELETE /mail_logs/1 or /mail_logs/1.json
  # def destroy
  #   @mail_log.destroy!
  #
  #   respond_to do |format|
  #     format.html { redirect_to notifications_url, notice: "Mail log was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  def refresh
    FetchMailgunInfos.call
    FetchTwilioInfos.call
    redirect_to(notifications_path, notice: 'Actualisation réussie')
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mail_log
    @mail_log = MailLog.find_by(slug: params[:id])
    return unless @mail_log.nil?

    redirect_to root_path, alert: 'Notification introuvable'
  end

  # Only allow a list of trusted parameters through.
  def mail_log_params
    params.require(:mail_log).permit(:to, :subject, :message_id, :user_id)
  end

  def is_user_authorized
    authorize @mail_log || MailLog
  end
end
