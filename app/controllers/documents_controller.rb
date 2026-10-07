# frozen_string_literal: true

class DocumentsController < ApplicationController
  before_action :is_user_authorized

  def documents
    @documents = ActiveStorage::Attachment.where(record_type: ["Convention", "Tool"])
                                        .order('created_at DESC')
                                        .order('created_at DESC')

    @services  = current_user.get_services_by_role
    @adherents = User.by_service(@services).adhérent.ordered
  end

  private 


  def is_user_authorized
    authorize :documents
  end
end
