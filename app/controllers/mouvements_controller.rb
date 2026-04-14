class MouvementsController < ApplicationController
  before_action :set_mouvement, only: %i[ show edit update destroy ]
  before_action :is_user_authorized

  # GET /mouvements or /mouvements.json
  def index
    @mouvements = current_user.organisation.mouvements
    @tools = current_user.organisation.tools.ordered
    @états = Mouvement.états.keys

    if params[:tool_ids].present?
      @mouvements = @mouvements.where(tool_id: params[:tool_ids])
    end

    # if params[:date].present?
    #   @mouvements = @mouvements.joins(:intervention).where("DATE(interventions.début) = ?", params[:date])
    # end

    if params[:etats].present?
      @mouvements = @mouvements.where(état: params[:etats])
    end
    @mouvements = @mouvements.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @mouvements = pagy(@mouvements, items: 10)
  end

  # GET /mouvements/1 or /mouvements/1.json
  def show
  end

  # GET /mouvements/new
  def new
    @mouvement = Mouvement.new(date: Time.current)
    @tools = current_user.organisation.tools.ordered
  end

  # GET /mouvements/1/edit
  def edit
  end

  # POST /mouvements or /mouvements.json
  def create
    @mouvement = Mouvement.new(mouvement_params)
    @mouvement.user_id = current_user.id

    respond_to do |format|
      if @mouvement.save
        format.html { redirect_to @mouvement.tool, notice: "Mouvement créé avec succès." }
        format.json { render :show, status: :created, location: @mouvement }
      else
        @tools = current_user.organisation.tools.ordered
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @mouvement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mouvements/1 or /mouvements/1.json
  def update
    respond_to do |format|
      if @mouvement.update(mouvement_params)
        format.html { redirect_to request.referrer, notice: "Mouvement modifié avec succès.", status: :see_other }
        format.json { render :show, status: :ok, location: @mouvement }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @mouvement.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /mouvements/1 or /mouvements/1.json
  def destroy
    # On retrouve la paire (sortie + entrée) grâce au timestamp de création exact
    mouvements_lies = Mouvement.where(
      tool_id: @mouvement.tool_id,
      user_id: @mouvement.user_id,
      created_at: @mouvement.created_at
    )

    # On supprime l'ensemble dans une transaction sécurisée
    Mouvement.transaction do
      mouvements_lies.destroy_all
    end

    redirect_back fallback_location: tools_path, notice: "La réservation a bien été annulée."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_back fallback_location: tools_path, alert: "Erreur lors de l'annulation de la réservation."
  end

  def reserve
    @tool = Tool.find(params[:tool_id])
    base_date = Date.parse(params[:date])

    start_time = base_date.in_time_zone.change(hour: params[:start_hour].to_i, min: params[:start_minute].to_i)
    end_time = base_date.in_time_zone.change(hour: params[:end_hour].to_i, min: 0)

    # On s'assure que les deux mouvements sont créés ensemble et en même temps (pour la suppression groupé)
    timestamp_exact = Time.current
    # Mouvement.transaction do
      @tool.mouvements.create!(état: :sortie, date: start_time, user: current_user, created_at: timestamp_exact)
      @tool.mouvements.create!(état: :entrée, date: end_time, user: current_user, created_at: timestamp_exact)
    # end

    redirect_back fallback_location: tools_path, notice: "Outil réservé avec succès."
  rescue ActiveRecord::RecordInvalid
    redirect_back fallback_location: tools_path, alert: "Erreur lors de la réservation de l'outil."
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
      params.expect(mouvement: [ :tool_id, :état, :commentaires, :date ])
    end

    def is_user_authorized
      authorize @mouvement ? @mouvement : Mouvement
    end

    def sortable_columns
      ['mouvements.updated_at', 'tools.name', 'mouvements.état']
    end

    def sort_column
      sortable_columns.include?(params[:column]) ? params[:column] : "mouvements.updated_at"
    end

    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
    end
end
