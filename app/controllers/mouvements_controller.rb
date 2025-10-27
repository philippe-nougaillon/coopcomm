class MouvementsController < ApplicationController
  before_action :set_mouvement, only: %i[ show edit update destroy ]
  before_action :is_user_authorized

  # GET /mouvements or /mouvements.json
  def index
    @mouvements = current_user.organisation.mouvements
  end

  # GET /mouvements/1 or /mouvements/1.json
  def show
  end

  # GET /mouvements/new
  def new
    @mouvement = Mouvement.new
  end

  # GET /mouvements/1/edit
  def edit
  end

  # POST /mouvements or /mouvements.json
  def create
    @mouvement = Mouvement.new(mouvement_params)

    respond_to do |format|
      if @mouvement.save
        format.html { redirect_to @mouvement, notice: "Mouvement was successfully created." }
        format.json { render :show, status: :created, location: @mouvement }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @mouvement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mouvements/1 or /mouvements/1.json
  def update
    respond_to do |format|
      if @mouvement.update(mouvement_params)
        format.html { redirect_to @mouvement, notice: "Mouvement was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @mouvement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @mouvement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mouvements/1 or /mouvements/1.json
  def destroy
    @mouvement.destroy!

    respond_to do |format|
      format.html { redirect_to mouvements_path, notice: "Mouvement was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mouvement
      @mouvement = Mouvement.find_by(slug: params[:id])
      if @mouvement.nil?
        redirect_to root_path, alert: "Mouvement introuvable"
      end
    end

    # Only allow a list of trusted parameters through.
    def mouvement_params
      params.expect(mouvement: [ :tool_id, :état, :slug ])
    end

    def is_user_authorized
      authorize @mouvement ? @mouvement : Mouvement
    end
end
