# frozen_string_literal: true

class WikiPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show blog guide faq]
  before_action :set_wiki_page, only: %i[show edit update destroy purge_photo purge_document copie copier]
  before_action :is_user_authorized

  # GET /documentation
  def index
    @wiki_pages = WikiPage.by_role_for(current_user)
                          .with_attached_document

    # Renvoie sur la page pour les recherches
    if params[:search].present?
      @wiki_pages = @wiki_pages.search_titre_and_contenu("%#{params[:search]}%")
      render :index_for_search
    else # Ou renvoie sur la page principale
      @wiki_pages = @wiki_pages
    end
  end

  # GET /documentation/1
  def show; end

  # GET /documentation/new
  def new
    @wiki_page = WikiPage.new(catégorie: params[:catégorie].presence_in(WikiPage.catégories.keys))
  end

  # GET /documentation/1/edit
  def edit; end

  # POST /documentation
  def create
    @wiki_page = WikiPage.new(wiki_page_params)
    @wiki_page.user_id = current_user.id

    if @wiki_page.save
      redirect_to documentation_url(@wiki_page), notice: 'Documentation créée avec succès.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /documentation/1
  def update
    if @wiki_page.update(wiki_page_params)
      redirect_to documentation_url(@wiki_page), notice: 'Documentation modifiée avec succès.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /documentation/1
  def destroy
    @wiki_page.discard

    redirect_to documentation_index_url, notice: 'Documentation supprimée avec succès.'
  end

  # GET /documentation/blog
  def blog
    @catégorie = "blog"
    @wiki_pages = WikiPage.by_role_for(current_user)
                          .by_categorie(@catégorie)
                          .order(:poids)
                          .with_attached_document
    render :index_by_categorie
  end

  # GET /documentation/guide
  def guide
    @catégorie = "guide"
    @wiki_pages = WikiPage.by_role_for(current_user)
                          .by_categorie(@catégorie)
                          .order(:poids)
                          .with_attached_document
    render :index_by_categorie
  end

  # GET /documentation/faq
  def faq
    @catégorie = "faq"
    @wiki_pages = WikiPage.by_role_for(current_user)
                          .by_categorie(@catégorie)
                          .order(:poids)
                          .with_attached_document
    render :index_by_categorie
  end

  def purge_photo
    authorize @wiki_page, :edit?
    @wiki_page.photo.purge
    redirect_to documentation_path(@wiki_page), notice: 'Photo supprimée avec succès.'
  end

  def purge_document
    authorize @wiki_page, :purge_document?
    @wiki_page.document.purge
    redirect_to documentation_path(@wiki_page), notice: "Le document a été supprimé."
  end

  # GET /documentation/1/copie
  def copie
    @instances = instances_cibles
    @instance = @instances.find { |instance| instance[:nom] == params[:instance] }
    @auteurs = AppelerInstance.call(@instance[:url], '/copies_wiki/auteurs') if @instance
  rescue AppelerInstance::Erreur => e
    flash.now[:alert] = e.message
  end

  # POST /documentation/1/copier
  def copier
    instance = instances_cibles.find { |cible| cible[:nom] == params[:instance] }
    return redirect_to copie_documentation_path(@wiki_page), alert: 'Instance inconnue.' unless instance

    page_copiée = AppelerInstance.call(instance[:url], '/copies_wiki',
                                       { page: ExporterPageWiki.call(@wiki_page), auteur: params[:auteur],
                                         publiée: params[:publiée] == '1',
                                         origine: { instance: ENV['HOST_URL'], slug: @wiki_page.slug,
                                                    par: current_user.email } })
    redirect_to URI.join(instance[:url], documentation_path(page_copiée['slug'])).to_s,
                allow_other_host: true, status: :see_other
  rescue AppelerInstance::Erreur => e
    redirect_to copie_documentation_path(@wiki_page, instance: instance[:nom]), alert: e.message
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_wiki_page
    @wiki_page = WikiPage.friendly.find(params[:id])
  rescue StandardError
    redirect_to root_path, alert: 'Documentation introuvable' if @wiki_page.nil?
  end

  # Only allow a list of trusted parameters through.
  def wiki_page_params
    params.require(:wiki_page).permit(:titre, :sous_titre, :publiée, :poids, :contenu, :catégorie, :épinglée,
                                      :document, :photo, :private)
  end

  def is_user_authorized
    authorize @wiki_page || WikiPage
  end

  # INSTANCES_COOPCOMM : « Nom=https://hôte,Nom=https://hôte », la même sur toutes les instances
  def instances_cibles
    ENV['INSTANCES_COOPCOMM'].to_s.split(',').filter_map do |instance|
      nom, url = instance.split('=', 2).map(&:strip)
      { nom: nom, url: url } if url.present? && URI(url).host != ENV['HOST_URL']
    end
  end

end
