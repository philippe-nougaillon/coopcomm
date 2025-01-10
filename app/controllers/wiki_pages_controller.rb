class WikiPagesController < ApplicationController
  before_action :is_user_authorized, except: %i[ index show ]
  skip_before_action :authenticate_user!, only: %i[ index show ]
  before_action :set_wiki_page, only: %i[ show edit update destroy ]

  # GET /wiki_pages or /wiki_pages.json
  def index
    case params[:catégorie]
    when 'documentation'
      @wiki_pages = WikiPage.documentation
    when 'guide'
      @wiki_pages = WikiPage.guide
    when 'fiche'
      @wiki_pages = WikiPage.fiche
    else
      @wiki_pages = WikiPage.where(épinglée: true)
    end

    if params[:search].present?
      @wiki_pages = WikiPage.search_titre_and_contenu("%#{ params[:search] }%")
    end

    unless user_signed_in? && current_user.super_admin?
      @wiki_pages = @wiki_pages.where(publiée: true)
    end


    @wiki_pages.order(poids: :desc)
  end

  # GET /wiki_pages/1 or /wiki_pages/1.json
  def show
  end

  # GET /wiki_pages/new
  def new
    @wiki_page = WikiPage.new
  end

  # GET /wiki_pages/1/edit
  def edit
  end

  # POST /wiki_pages or /wiki_pages.json
  def create
    @wiki_page = WikiPage.new(wiki_page_params)

    respond_to do |format|
      if @wiki_page.save
        format.html { redirect_to wiki_page_url(@wiki_page), notice: "Wiki page was successfully created." }
        format.json { render :show, status: :created, location: @wiki_page }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @wiki_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wiki_pages/1 or /wiki_pages/1.json
  def update
    respond_to do |format|
      if @wiki_page.update(wiki_page_params)
        format.html { redirect_to wiki_page_url(@wiki_page), notice: "Wiki page was successfully updated." }
        format.json { render :show, status: :ok, location: @wiki_page }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @wiki_page.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wiki_pages/1 or /wiki_pages/1.json
  def destroy
    @wiki_page.destroy!

    respond_to do |format|
      format.html { redirect_to wiki_pages_url, notice: "Wiki page was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wiki_page
      @wiki_page = WikiPage.friendly.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def wiki_page_params
      params.require(:wiki_page).permit(:titre, :publiée, :poids, :contenu, :catégorie, :épinglée)
    end

    def is_user_authorized
      authorize @wiki_page ? @wiki_page : WikiPage
    end
end
