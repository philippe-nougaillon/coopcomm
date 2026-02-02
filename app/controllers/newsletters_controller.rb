class NewslettersController < ApplicationController
  before_action :set_newsletter, only: %i[ destroy ]
  before_action :is_user_authorized
  skip_before_action :authenticate_user!, only: %i[ new destroy ]


  # GET /newsletters or /newsletters.json
  def index
    @newsletters = Newsletter.order(created_at: :desc)

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
  # def create
  #   @newsletter = Newsletter.new(newsletter_params)
  #   if @newsletter.save
  #     flash[:notice] = "Inscription réussie"
  #     respond_to do |format|
  #       format.html { redirect_to welcome_path }
  #       format.turbo_stream { redirect_to welcome_path }
  #     end
  #   else
  #     flash[:alert] = "Inscription non valide, le mail est déjà inscrit"
  #     respond_to do |format|
  #       format.html { redirect_to welcome_path }
  #       format.turbo_stream { redirect_to welcome_path }
  #     end
  #   end
  # end

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

  def new

    if (email = params["email"])
      newsletter = Newsletter.new(email: email)
      if newsletter.save
        result = "Votre inscription a bien été effectuée."
        valid = true
        unless Rails.env.development?
          Events.instance.publish('create.newsletter', payload: {newsletter_id: newsletter.id})
        end
      else
        result = "Oups ! Il existe déjà une inscription pour cette adresse mail..."
      end
      
      render partial: "pages/result_newsletter", locals: { result: result, valid: valid }
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
