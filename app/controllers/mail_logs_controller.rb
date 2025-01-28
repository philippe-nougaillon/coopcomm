class MailLogsController < ApplicationController
  before_action :set_mail_log, only: %i[ show edit update destroy ]
  before_action :is_user_authorized
  before_action :update_twilio_logs, only: :index
  before_action :get_mailgun_infos, only: :index

  # GET /mail_logs or /mail_logs.json
  def index
    @organisation_mail_logs = current_user.organisation.mail_logs
    @mail_logs = @organisation_mail_logs.ordered

    @emails = current_user.organisation.users.pluck(:email).sort

    unless params[:search].blank?
      @mail_logs = @mail_logs.where("LOWER(mail_logs.to) like :search", {search: "%#{params[:search]}%".downcase})
    end

    unless params[:search_subject].blank?
      @mail_logs = @mail_logs.where(subject: params[:search_subject])
    end

    if params[:ko].blank?
      @result_opened = @mg_client.get("#{@domain}/events", {:event => 'opened'}).to_h
      @pagy, @mail_logs = pagy(@mail_logs)
    end
  end

  # GET /mail_logs/1 or /mail_logs/1.json
  def show
    mg_client = Mailgun::Client.new ENV["MAILGUN_API_KEY"], 'api.eu.mailgun.net'
    domain = ENV["MAILGUN_DOMAIN"]
    @result = mg_client.get("#{domain}/events", {:event => 'failed'}).to_h
    @result_opened = mg_client.get("#{domain}/events", {:event => 'opened'}).to_h
  end

  # GET /mail_logs/new
  def new
    @mail_log = MailLog.new
  end

  # GET /mail_logs/1/edit
  def edit
  end

  # POST /mail_logs or /mail_logs.json
  def create
    @mail_log = MailLog.new(mail_log_params)

    respond_to do |format|
      if @mail_log.save
        format.html { redirect_to mail_log_url(@mail_log), notice: "Mail log was successfully created." }
        format.json { render :show, status: :created, location: @mail_log }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @mail_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mail_logs/1 or /mail_logs/1.json
  def update
    respond_to do |format|
      if @mail_log.update(mail_log_params)
        format.html { redirect_to mail_log_url(@mail_log), notice: "Mail log was successfully updated." }
        format.json { render :show, status: :ok, location: @mail_log }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @mail_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mail_logs/1 or /mail_logs/1.json
  def destroy
    @mail_log.destroy!

    respond_to do |format|
      format.html { redirect_to mail_logs_url, notice: "Mail log was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mail_log
      @mail_log = MailLog.find_by(slug: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def mail_log_params
      params.require(:mail_log).permit(:to, :subject, :message_id, :organisation_id, :user_id)
    end

    def is_user_authorized
      authorize @mail_log ? @mail_log : MailLog
    end

    def update_twilio_logs
      tw_client = Twilio::REST::Client.new(ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN'])
      whatsapp_logs = MailLog.where(created_at: [DateTime.now-20.minutes..DateTime.now], channel: 1)

      whatsapp_logs.each do |whatsapp_log|
        message = tw_client.messages(whatsapp_log.message_id).fetch
        if whatsapp_log.statut && message.status == "failed"
          whatsapp_log.update!(statut: false, error_message: message.error_code)
        end
        if !whatsapp_log.etat && message.status == "read"
          whatsapp_log.update!(etat: true)
        end
      end
    end

    def get_mailgun_infos
      @mg_client = Mailgun::Client.new ENV["MAILGUN_API_KEY"], 'api.eu.mailgun.net'
      @domain = ENV["MAILGUN_DOMAIN"]
      @result_failed = @mg_client.get("#{@domain}/events", {:event => 'failed'}).to_h
      @result_opened = {}.to_h
    end
end
