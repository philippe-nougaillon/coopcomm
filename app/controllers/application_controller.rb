class ApplicationController < ActionController::Base
  include Pagy::Backend
  include DefaultRateLimits
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Pagy::OverflowError, with: :pagy_wrong_page
  before_action :authenticate_user!
  before_action :prepare_exception_notifier

  helper_method :sort_column, :sort_direction

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
end
