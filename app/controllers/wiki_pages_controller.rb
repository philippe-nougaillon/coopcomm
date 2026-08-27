# frozen_string_literal: true

class WikiPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]
  before_action :set_wiki_page, only: %i[show edit update destroy]
  before_action :is_user_authorized

  # GET /documentation
  def index
    @catégorie = params[:catégorie] if WikiPage.catégories.key?(params[:catégorie])

    if params[:search].present?
      @wiki_pages = pages_visibles(WikiPage.search_titre_and_contenu("%#{params[:search]}%"))
    elsif @catégorie
      @wiki_pages = pages_visibles(WikiPage.where(catégorie: @catégorie))
    else
      @épinglées_par_catégorie = WikiPage.catégories.keys.index_with do |catégorie|
        pages_visibles(WikiPage.where(catégorie:, épinglée: true))
          .with_attached_document
          .with_rich_text_contenu
          .limit(3)
      end
    end
  end

  # GET /documentation/1
  def show; end

  # GET /documentation/new
  def new
    @wiki_page = WikiPage.new
  end

  # GET /documentation/1/edit
  def edit; end

  # POST /documentation
  def create
    @wiki_page = WikiPage.new(wiki_page_params)
    @wiki_page.user_id = current_user.id

    if @wiki_page.save
      redirect_to documentation_url(@wiki_page), notice: 'Page wiki créée avec succès.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /documentation/1
  def update
    if @wiki_page.update(wiki_page_params)
      redirect_to documentation_url(@wiki_page), notice: 'Page wiki modifiée avec succès.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /documentation/1
  def destroy
    @wiki_page.discard

    redirect_to documentation_index_url, notice: 'Page wiki supprimée avec succès.'
  end

  private

  def pages_visibles(pages)
    pages = pages.where(publiée: true) unless policy(WikiPage).new?
    pages = pages.where(private: false) if !user_signed_in? || current_user.agent?
    pages.order(:poids)
  end

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
