# frozen_string_literal: true

class MouvementsController < ApplicationController
  before_action :set_mouvement, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /mouvements or /mouvements.json
  def index
    @mouvements = current_organisation.mouvements
    @tools = current_organisation.tools.ordered
    @états = Mouvement.états.keys

    @mouvements = @mouvements.where(tool_id: params[:tool_ids]) if params[:tool_ids].present?

    # if params[:date].present?
    #   @mouvements = @mouvements.joins(:intervention).where("DATE(interventions.début) = ?", params[:date])
    # end

    @mouvements = @mouvements.where(état: params[:etats]) if params[:etats].present?

    @mouvements = @mouvements.includes(:tool, :user)

    @mouvements = @mouvements.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @mouvements = pagy(@mouvements, items: 10)
  end

  # GET /mouvements/1 or /mouvements/1.json
  def show; end

  # GET /mouvements/new
  def new
    @mouvement = Mouvement.new(date: Time.current)
    @tools = current_organisation.tools.ordered
  end

  # GET /mouvements/1/edit
  def edit; end

  # POST /mouvements or /mouvements.json
  def create
    @mouvement = Mouvement.new(mouvement_params)
    @mouvement.user_id = current_user.id

    respond_to do |format|
      if @mouvement.save
        format.html { redirect_to @mouvement.tool, notice: 'Mouvement créé avec succès.' }
        format.json { render :show, status: :created, location: @mouvement }
      else
        @tools = current_organisation.tools.ordered
        params[:tool_id] = params[:mouvement][:tool_id]
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @mouvement.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /mouvements/1 or /mouvements/1.json
  def update
    respond_to do |format|
      if @mouvement.update(mouvement_params)
        format.html { redirect_to @mouvement.tool, notice: 'Mouvement modifié avec succès.', status: :see_other }
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

    mouvement_date = mouvements_lies.first.date.to_date
    # On supprime l'ensemble dans une transaction sécurisée
    Mouvement.transaction do
      mouvements_lies.destroy_all
    end

    redirect_back fallback_location: tools_path, notice: "La réservation du #{l mouvement_date} a bien été annulée."
  rescue ActiveRecord::RecordNotDestroyed
    redirect_back fallback_location: tools_path, alert: "Erreur lors de l'annulation de la réservation."
  end

  def reserve
    @tool = Tool.find(params[:tool_id])
    date = Date.parse(params[:date])

    @tool.mouvements.create!(état: :réservé, date: date, user: current_user)

    redirect_back fallback_location: tools_path, notice: "Outil réservé le #{l date} avec succès."
  end

  def libere
    if params[:tool_id] && params[:date] && params[:user_id]
      if mouvement = Mouvement.find_by(tool_id: params[:tool_id], date: params[:date], user_id: params[:user_id])
        mouvement.destroy
      end
      redirect_to tools_path, notice: "Outil libéré pour le #{l params[:date].to_date}."
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_mouvement
    @mouvement = Mouvement.find_by(slug: params[:id])
    return unless @mouvement.nil?

    redirect_to root_path, alert: 'Mouvement introuvable'
  end

  # Only allow a list of trusted parameters through.
  def mouvement_params
    params.expect(mouvement: %i[tool_id état commentaires date])
  end

  def is_user_authorized
    authorize @mouvement || Mouvement
  end

  def sortable_columns
    ['mouvements.updated_at', 'tools.name', 'mouvements.état']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'mouvements.updated_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
