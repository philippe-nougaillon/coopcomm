# frozen_string_literal: true

class PrestationsController < ApplicationController
  before_action :set_prestation, only: %i[show edit update destroy]
  before_action :is_user_authorized

  
  def show; end
  
  # GET /prestations/new
  def new
    @prestation = Prestation.new
  end

  
  # GET /prestations/1/edit
  def edit; end

  # POST /prestations
  def create
    @prestation = current_organisation.prestations.new(prestation_params)

    if @prestation.save
      redirect_to admin_parametres_path(tab: target_tab),  notice: 'Prestation créée.'
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /prestations/1
  def update
    if @prestation.update(prestation_params)
      redirect_to admin_parametres_path(tab: 'prestations'),  notice: 'Prestation mise à jour.', status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /prestations/1
  def destroy
    if @prestation.destroy
      redirect_to admin_parametres_path(tab: 'prestations'), notice: 'Prestation supprimée.', status: :see_other
    else
       redirect_to admin_parametres_path(tab: 'prestations'), alert: @prestation.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private

  def set_prestation
    @prestation = current_organisation.prestations.find_by(slug: params[:id])
    redirect_to admin_parametres_path(tab: 'prestations'), alert: 'Prestation introuvable' if @prestation.nil?
  end

  def is_user_authorized
    authorize(@prestation || Prestation)
  end

  def target_tab
    params[:tab].presence || 'prestations'
  end

  def prestation_params
    params.require(:prestation).permit(
      :code, :libellé, :catégorie, :sous_catégorie, :description, :unité, :tarif, :compétence, :délai
    )
  end
end
