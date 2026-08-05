# frozen_string_literal: true

class ToolsController < ApplicationController
  before_action :set_tool, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /tools or /tools.json
  def index
    params[:date] = Date.today unless date_valide?(params[:date])
    start_date = params[:date].to_date

    @date = start_date.beginning_of_week # Ce sera toujours le lundi.
    @date_fin = start_date.end_of_week   # Ce sera toujours le dimanche.
    @tools = current_organisation.tools.ordered
    @types = Tool.icons
    # @états = Mouvement.états.keys

    if params[:search].present?
      @tools = @tools.where('name ILIKE :search OR description ILIKE :search', { search: "%#{params[:search]}%" })
    end

    @tools = @tools.where(icon_name: params[:type]) if params[:type].present?

    # if params[:etats].present?
    #   tool_ids = []
    #   @tools.each do |tool|
    #     tool_ids << tool.id if tool.mouvements.last.état == params[:etats]
    #   end
    #   @tools = @tools.where(id: tool_ids)
    # end

    @forecasts = MeteoConceptConnexion.call

    @tools = @tools.reorder(Arel.sql("#{sort_column} #{sort_direction}, tools.id #{sort_direction}"))
    @pagy, @tools = pagy(@tools, items: 10)
  end

  # GET /tools/1 or /tools/1.json
  # GET /tools/1 or /tools/1.json
  def show
    params[:vue] ||= 'calendrier'
    @documents = @tool.documents

    # start_date est le paramètre de navigation de simple_calendar
    start_date = params[:start_date].presence || params[:date]
    start_date = Date.today unless date_valide?(start_date)

    @date = start_date.to_date.beginning_of_month
    @date_fin = @date.end_of_month

    @date_inicio_grid = @date.beginning_of_week
    @date_fin_grid = @date_fin.end_of_week
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
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @tool.errors, status: :unprocessable_content }
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
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @tool.errors, status: :unprocessable_content }
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
    
    if @tool.nil?
      redirect_to root_path, alert: 'Matériel introuvable'
    end
  end

  # Only allow a list of trusted parameters through.
  def tool_params
    params.require(:tool).permit(:name, :description, :icon_name, :modèle, :marque, :photo, :document)
  end

  def is_user_authorized
    authorize @tool || Tool
  end

  def sortable_columns
    ['tools.name', 'tools.modèle', 'tools.marque', 'tools.icon_name', 'mouvements.état']
  end

  def sort_column
    base = sortable_columns.include?(params[:column]) ? params[:column] : 'tools.name'
    base == 'tools.name' ? 'LOWER(unaccent(tools.name))' : base
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  # to_date renvoie nil sur une chaîne vide et lève sur une chaîne illisible.
  def date_valide?(valeur)
    valeur.to_s.to_date.present?
  rescue Date::Error
    false
  end
end