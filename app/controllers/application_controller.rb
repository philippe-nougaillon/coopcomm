# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  include Triable
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Pagy::OverflowError, with: :pagy_wrong_page
  before_action :authenticate_user!
  before_action :prepare_exception_notifier
  # Toute action qui oublie `authorize` lève une erreur. Exemption ponctuelle :
  # `skip_after_action :verify_authorized`.
  after_action :verify_authorized, unless: :devise_controller?

  helper_method :current_organisation

  # Historique d'activité : le même tableau est rendu dans plusieurs show.
  trie Audited::Audit, ColonnesTri.audits, defaut: 'audits.created_at', sens: :desc

  # logique déplacée dans config/initializers/rack_attack.rb
  # rate_limit to: 20, within: 1.minute,
  #            by: -> { request.ip },
  #            if: -> { devise_controller? }

  BACKGROUND_COLORS = {
    8 => '#c7c375',
    10 => '#d7d385',
    12 => '#fbf098',
    14 => '#a1ab6f',
    16 => '#eca95c',
    18 => '#b7726c',
    20 => '#2e3d58'
  }.freeze

  def current_organisation
    @current_organisation ||= current_user.organisation
  end

  private

  def prepare_exception_notifier
    request.env['exception_notifier.exception_data'] = {
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

  def set_users_tags
    @users_tags = User.by_service(current_user).tag_counts_on(:tags).reorder(Arel.sql(TriTextuel.expression('tags.name')))
  end

  
  # Périmètre de services d'un index. Renseigne @services (options du menu) et
  # @selected_service_ids (sélection).
  def scoped_services(param_key, admin_sees_all: false)
    default_services = current_user.services
    allowed_services = (current_user.administrateur? && current_organisation&.services) || default_services
    @services = allowed_services.ordered

    # Premier affichage : filtre non soumis.
    unless params.key?(param_key)
      if current_user.administrateur? && !admin_sees_all
        @selected_service_ids = default_services.ids
        return default_services
      end

      @selected_service_ids = []
      return allowed_services
    end

    requested = allowed_services.where(id: params[param_key])
    if requested.present?
      @selected_service_ids = requested.ids
      requested
    else
      @selected_service_ids = []
      allowed_services
    end
  end

  def after_sign_out_path_for(resource_or_scope)
      root_path
    end
end