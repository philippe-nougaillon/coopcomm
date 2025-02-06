class ToolsController < ApplicationController
  before_action :set_tool, only: %i[ show edit update destroy ]
  before_action :is_user_authorized

  # GET /tools or /tools.json
  def index
    params[:vue] ||= 'tout'
    params[:quand] = DateTime.now.strftime("%Y-%m-%dT%H:%M") if params[:quand].blank?
    @tools = current_user.organisation.tools.ordered

    if params[:search].present?
      @tools = @tools.where("name ILIKE :search OR description ILIKE :search", {search: "%#{params[:search]}%"})
    end

    case params[:vue]
    when 'disponible'
      @tools = @tools.where.not(id: Tool.indisponibles_ids(current_user.organisation_id, params[:quand]))
    when 'indisponible'
      @tools = @tools.where(id: Tool.indisponibles_ids(current_user.organisation_id, params[:quand]))
    when 'indisponible_carte'
      @tools = @tools.where(id: Tool.indisponibles_ids(current_user.organisation_id, params[:quand]))
      @lng = []
      @lat = []
      current_user.organisation.users.where.not(memo: nil).pluck(:memo).uniq.each do |memo|
        if memo.include?('[')
          @lng << memo.tr('[]', '').split(',').last
          @lat << memo.tr('[]', '').split(',').first
        end
      end
    end

    @pagy, @tools = pagy(@tools, items: 15)
  end

  # GET /tools/1 or /tools/1.json
  def show
  end

  # GET /tools/new
  def new
    @tool = Tool.new
  end

  # GET /tools/1/edit
  def edit
  end

  # POST /tools or /tools.json
  def create
    @tool = Tool.new(tool_params)
    @tool.organisation = current_user.organisation

    respond_to do |format|
      if @tool.save
        format.html { redirect_to tools_url(@tool), notice: "Outil créé avec succès." }
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
        format.html { redirect_to tool_url(@tool), notice: "Outil modifié avec succès." }
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
      format.html { redirect_to tools_url, notice: "Outil supprimé avec succès." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tool
      @tool = Tool.find_by(slug: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tool_params
      params.require(:tool).permit(:name, :description)
    end

    def is_user_authorized
      authorize @tool ? @tool : Tool
    end
end
