# frozen_string_literal: true

class MouvementsController < ApplicationController
  before_action :set_mouvement, only: %i[show edit update]
  before_action :set_reservation_a_liberer, only: %i[libere]
  before_action :is_user_authorized

  # Défini la route du redirect
  before_action :set_redirect_path, only: %i[new edit create update]

  trie Mouvement, defaut: 'mouvements.updated_at', sens: :desc

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

    @mouvements = trier(@mouvements)
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
    # L'outil doit appartenir à l'organisation courante (tool_id forgeable)
    @mouvement.tool = current_organisation.tools.find_by(id: mouvement_params[:tool_id])
    @mouvement.user_id = current_user.id

    respond_to do |format|
      if @mouvement.save
        format.html { redirect_to @redirect_to, notice: 'Mouvement créé avec succès.' }
        format.json { render :show, status: :created, location: @mouvement }
      else
        @tools = current_organisation.tools.ordered
        # Pas de params[:tool_id] = ... ici : le formulaire renvoie lui-même un tool_id
        # de premier niveau quand l'outil est imposé (cf. _form.html.erb). Le réécrire
        # cacherait à tort le select quand l'outil avait été librement choisi.
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @mouvement.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /mouvements/1 or /mouvements/1.json
  def update
    safe_params = mouvement_params
    # Empêche de déplacer le mouvement vers l'outil d'une autre organisation
    safe_params = safe_params.except(:tool_id) if safe_params[:tool_id].present? && !current_organisation.tools.exists?(id: safe_params[:tool_id])

    respond_to do |format|
      if @mouvement.update(safe_params)
        format.html { redirect_to @redirect_to, notice: 'Mouvement modifié avec succès.', status: :see_other }
        format.json { render :show, status: :ok, location: @mouvement }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @mouvement.errors, status: :unprocessable_content }
      end
    end
  end

  def reserve
    @tool = current_organisation.tools.find(params[:tool_id])
    date = Date.parse(params[:date].to_s)

    @tool.mouvements.create!(état: :réservé, date: date, user: current_user)
    redirect_back fallback_location: tools_path, notice: "#{@tool.name} réservé.e le #{l date} avec succès."
  rescue Date::Error
    redirect_back fallback_location: tools_path, alert: 'Date de réservation invalide.'
  end

  def libere
    if @mouvement.destroy
      redirect_back fallback_location: tools_path, notice: "#{@mouvement.tool.name} libéré.e pour le #{l params[:date].to_date}."
    else
      redirect_back fallback_location: tools_path, alert: "#{@mouvement.tool.name} n'a pas pu être libéré.e : #{@mouvement.errors.full_messages.to_sentence}."
    end
  end

  private

  # Détermine de manière fiable la page vers laquelle rediriger l'utilisateur après le traitement du formulaire
  def set_redirect_path
    @redirect_to = params[:redirect_to].present? ? params[:redirect_to] : mouvements_path
  end

  # Charge la réservation visée avant l'autorisation, pour que la policy statue
  # sur l'enregistrement et non sur la classe.
  def set_reservation_a_liberer
    @mouvement = current_organisation.mouvements.find_by(
      tool_id: params[:tool_id],
      date: params[:date],
      user_id: params[:user_id],
      état: 'réservé'
    )
    return unless @mouvement.nil?

    redirect_back fallback_location: tools_path,
                  alert: "Il n'existe pas de réservation ce jour-là pour cet utilisateur."
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_mouvement
    @mouvement = Mouvement.find_by(slug: params[:id])
    
    if @mouvement.nil?
      redirect_back fallback_location: root_path, alert: 'Mouvement introuvable'
    end
  end

  # Only allow a list of trusted parameters through.
  def mouvement_params
    params.expect(mouvement: %i[tool_id état commentaires date])
  end

  def is_user_authorized
    authorize @mouvement || Mouvement
  end

end
