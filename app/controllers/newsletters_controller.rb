class NewslettersController < ApplicationController
  before_action :set_newsletter, only: %i[ destroy ]
  before_action :is_user_authorized
  skip_before_action :authenticate_user!, only: %i[ create destroy ]


  # GET /newsletters or /newsletters.json
  def index
    @newsletters = Newsletter.all

    respond_to do |format|
      format.html do
        @newsletters
      end

      format.xls do
        xls_file = NewslettersToXls.new(@newsletters).call
        send_data xls_file, filename: "Newsletters_#{DateTime.now}.xls"
      end
    end
  end

  # # GET /newsletters/1 or /newsletters/1.json
  # def show
  # end

  # # GET /newsletters/new
  # def new
  #   @newsletter = Newsletter.new
  # end

  # # GET /newsletters/1/edit
  # def edit
  # end

  # POST /newsletters or /newsletters.json
  def create
    @newsletter = Newsletter.new(newsletter_params)
    if verify_recaptcha(model: @newsletter) || Rails.env.test?
      if @newsletter.save
        flash[:notice] = "Inscription réussie"
        respond_to do |format|
          format.html { redirect_to root_path }
          format.turbo_stream { redirect_to root_path }
        end
      else
        flash[:alert] = "Inscription non valide, le mail est déjà inscrit"
        respond_to do |format|
          format.html { redirect_to root_path }
          format.turbo_stream { redirect_to root_path }
        end
      end
    else
      flash[:alert] = "Problème avec reCAPTCHA, merci de réessayer"
      respond_to do |format|
        format.html { redirect_to root_path }
        format.turbo_stream { redirect_to root_path }
      end
    end
  end

  # PATCH/PUT /newsletters/1 or /newsletters/1.json
  # def update
  #   respond_to do |format|
  #     if @newsletter.update(newsletter_params)
  #       format.html { redirect_to @newsletter, notice: "Newsletter was successfully updated." }
  #       format.json { render :show, status: :ok, location: @newsletter }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @newsletter.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /newsletters/1 or /newsletters/1.json
  def destroy
    @newsletter.destroy!

    respond_to do |format|
      format.html { redirect_to (user_signed_in? && current_user.super_admin?) ? newsletters_path : root_path, status: :see_other, notice: "Utilisateur désinscrit de la newsletter." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_newsletter
      @newsletter = Newsletter.find_by(slug: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def newsletter_params
      params.expect(newsletter: [ :email ])
    end

    def is_user_authorized
      authorize @newsletter ? @newsletter : Newsletter
    end
end
