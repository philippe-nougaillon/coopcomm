class DocumentsController < ApplicationController
  before_action :set_document, only: %i[valider refuser]
  before_action :is_user_authorized

  def valider
    @document.valider!
    redirect_to @document.tool, notice: "Document accepté"
  end

  def refuser
    @document.refuser!
    redirect_to @document.tool, notice: "Document refusé"
  end

  private
    def set_document
      @document = Document.find(params[:id])
    end

    def is_user_authorized
      authorize @document ? @document : Document
    end
end
