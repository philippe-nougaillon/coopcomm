# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :set_document, only: %i[valider refuser]
  before_action :is_user_authorized

  def valider
    if @document.valid?
      if @document.can_valider?
        @document.valider!
        redirect_to @document.tool, notice: 'Document accepté'
      elsif @document.validé?
        redirect_to @document.tool, alert: 'Le document est déjà validé'
      else
        redirect_to @document.tool, alert: 'Le document ne peut pas être validé'
      end
    else
      redirect_to @document.tool, alert: "Le document n'est pas valide. Elle ne peut pas être validé"
    end
  end

  def refuser
    if @document.valid?
      if @document.can_refuser?
        @document.refuser!
        redirect_to @document.tool, notice: 'Document refusé'
      elsif @document.refusé?
        redirect_to @document.tool, alert: 'Le document est déjà refusé'
      else
        redirect_to @document.tool, alert: 'Le document ne peut pas être refusé'
      end
    else
      redirect_to @document.tool, alert: "Le document n'est pas valide. Elle ne peut pas être refusé"
    end
  end

  private

  def set_document
    @document = Document.find_by(slug: params[:id])
    return unless @document.nil?

    redirect_to root_path, alert: 'Document introuvable'
  end

  def is_user_authorized
    authorize @document || Document
  end
end
