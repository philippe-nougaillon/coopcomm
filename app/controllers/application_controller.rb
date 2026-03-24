class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Pagy::OverflowError, with: :pagy_wrong_page
  before_action :authenticate_user!
  before_action :prepare_exception_notifier

  helper_method :sort_column, :sort_direction

  rate_limit to: 20, within: 1.minute, 
             by: -> { request.ip }, 
             if: -> { devise_controller? }

  BACKGROUND_COLORS = {
    8  => "#c7c375",
    10 => "#d7d385",
    12 => "#fbf098",
    14 => "#a1ab6f",
    16 => "#eca95c",
    18 => "#b7726c",
    20 => '#2e3d58'
  }

  private

  def prepare_exception_notifier
    request.env["exception_notifier.exception_data"] = {
      current_user: current_user
    }
  end

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à effectuer cette action."
    redirect_to(request.referrer || root_path)
  end

  def pagy_wrong_page
    redirect_to(request.referrer || request.path || root_path)
  end

  def set_organisation_user_tags
    if current_user&.organisation
      @users_tags = current_user.organisation.users.tag_counts_on(:tags).order(:name)
    end
  end
end
