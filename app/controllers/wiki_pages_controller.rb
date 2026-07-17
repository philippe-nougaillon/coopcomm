# frozen_string_literal: true

class WikiPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_wiki_page, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /wiki_pages or /wiki_pages.json
  def index
    @wiki_pages = case params[:catégorie]
                  when 'blog'
                    WikiPage.blog
                  when 'guide'
                    WikiPage.guide
                  when 'faq'
                    WikiPage.faq
                  else
                    WikiPage.where(épinglée: true)
                  end

    if params[:search].present?
      # PS : C'est voulu que ce soit WikiPage et pas @wiki_pages ? Ça annule le filtre sur les catégorie et les éplinglés ci-dessus
      @wiki_pages = WikiPage.search_titre_and_contenu("%#{params[:search]}%")
    end

    @wiki_pages = @wiki_pages.where(publiée: true) unless policy(WikiPage).new?

    @wiki_pages = @wiki_pages.where(private: false) if !user_signed_in? || current_user.agent?

    @wiki_pages = @wiki_pages.order(:poids)
  end

  # GET /wiki_pages/1 or /wiki_pages/1.json
  def show; end

  # GET /wiki_pages/new
  def new
    @wiki_page = WikiPage.new
  end

  # GET /wiki_pages/1/edit
  def edit; end

  # POST /wiki_pages or /wiki_pages.json
  def create
    @wiki_page = WikiPage.new(wiki_page_params)
    @wiki_page.user_id = current_user.id

    respond_to do |format|
      if @wiki_page.save
        format.html { redirect_to wiki_page_url(@wiki_page), notice: 'Page wiki créée avec succès.' }
        format.json { render :show, status: :created, location: @wiki_page }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @wiki_page.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /wiki_pages/1 or /wiki_pages/1.json
  def update
    respond_to do |format|
      if @wiki_page.update(wiki_page_params)
        format.html { redirect_to wiki_page_url(@wiki_page), notice: 'Page wiki modifiée avec succès.' }
        format.json { render :show, status: :ok, location: @wiki_page }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @wiki_page.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /wiki_pages/1 or /wiki_pages/1.json
  def destroy
    @wiki_page.discard

    respond_to do |format|
      format.html { redirect_to wiki_pages_url, notice: 'Page wiki supprimée avec succès.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_wiki_page
    @wiki_page = WikiPage.friendly.find(params[:id])
  rescue StandardError
    redirect_to root_path, alert: 'Page wiki introuvable' if @wiki_page.nil?
  end

  # Only allow a list of trusted parameters through.
  def wiki_page_params
    params.require(:wiki_page).permit(:titre, :sous_titre, :publiée, :poids, :contenu, :catégorie, :épinglée,
                                      :document, :private)
  end

  def is_user_authorized
    authorize @wiki_page || WikiPage
  end
end
