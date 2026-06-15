# frozen_string_literal: true

class MissionControlAdminController < ApplicationController
  before_action :require_admin
  # L'engine Mission Control n'utilise pas Pundit : acces garde par require_admin
  skip_after_action :verify_authorized

  private

  def require_admin
    raise ActiveRecord::RecordNotFound unless current_user.super_admin?
  end
end
