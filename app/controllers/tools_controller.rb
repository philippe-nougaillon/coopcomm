# frozen_string_literal: true

class ToolsController < ApplicationController
  before_action :set_tool, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /tools or /tools.json
  def index
    params[:vue] ||= 'calendrier'
    params[:date] = Date.today if params[:date].blank?
    @date = params[:date].to_date
    @tools = current_organisation.tools
    @types = Tool.icons
    @états = Mouvement.états.keys

    if params[:search].present?
      @tools = @tools.where('name ILIKE :search OR description ILIKE :search', { search: "%#{params[:search]}%" })
    end

    @tools = @tools.where(icon_name: params[:type]) if params[:type].present?

    if params[:etats].present?
      tool_ids = []
      @tools.each do |tool|
        tool_ids << tool.id if tool.mouvements.last.état == params[:etats]
      end
      @tools = @tools.where(id: tool_ids)
    end

    @forecasts = MeteoConceptConnexion.call

    case params[:vue]
    when 'calendrier'
      @date_fin = @date + 13.day
    when 'disponible'
      @tools = @tools.where.not(id: Tool.indisponibles_ids(current_organisation.id, params[:date]))
    when 'indisponible'
      @tools = @tools.where(id: Tool.indisponibles_ids(current_organisation.id, params[:date]))
    when 'indisponible_carte'
      @tools = @tools.where(id: Tool.indisponibles_ids(current_organisation.id, params[:date]))
      @lng_list = []
      @lat_list = []
      User.by_service(current_user.services).adhérent.pluck(:localisation).each do |localisation|
        @lng_list << localisation.split(',').last
        @lat_list << localisation.split(',').first
      end
    end

    @tools = @tools.with_attached_photo.ordered

    @tools = @tools.reorder(Arel.sql("#{sort_column} #{sort_direction}"))
    @pagy, @tools = pagy(@tools, items: 10)
  end

  # GET /tools/1 or /tools/1.json
  def show
    params[:vue] ||= 'calendrier'

    @documents = @tool.documents.with_attached_fichier
  end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/1/edit
  def edit; end

  # POST /tools or /tools.json
  def create
    @tool = Tool.new(tool_params)
    @tool.organisation = current_organisation

    respond_to do |format|
      if @tool.save
        format.html { redirect_to tool_url(@tool), notice: 'Outil créé avec succès.' }
        format.json { render :show, status: :created, location: @tool }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tool.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tools/1 or /tools/1.json
  def update
    respond_to do |format|
      if @tool.update(tool_params)
        format.html { redirect_to tool_url(@tool), notice: 'Outil modifié avec succès.' }
        format.json { render :show, status: :ok, location: @tool }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tool.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tools/1 or /tools/1.json
  def destroy
    @tool.destroy!

    respond_to do |format|
      format.html { redirect_to tools_url, notice: 'Outil supprimé avec succès.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_tool
    @tool = Tool.find_by(slug: params[:id])
    return unless @tool.nil?

    redirect_to root_path, alert: 'Matériel introuvable'
  end

  # Only allow a list of trusted parameters through.
  def tool_params
    params.require(:tool).permit(:name, :description, :icon_name, :modèle, :marque, :photo,
                                 documents_attributes: %i[id category workflow_state fichier])
  end

  def is_user_authorized
    authorize @tool || Tool
  end

  def sortable_columns
    ['tools.name', 'tools.modèle', 'tools.marque', 'tools.icon_name', 'mouvements.état']
  end

  def sort_column
    sortable_columns.include?(params[:column]) ? params[:column] : 'tools.name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
