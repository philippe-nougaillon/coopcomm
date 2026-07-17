# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from Pagy::OverflowError, with: :pagy_wrong_page
  before_action :authenticate_user!
  before_action :prepare_exception_notifier
  # Filet Pundit : toute action qui oublie `authorize` lève une erreur au lieu
  # de passer silencieusement (cf. AbsencesController#destroy avant l'audit).
  # Exemption ponctuelle : `skip_after_action :verify_authorized` + justification.
  after_action :verify_authorized, unless: :devise_controller?

  helper_method :sort_column, :sort_direction
  helper_method :current_organisation

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
    @users_tags = User.by_service(current_user).tag_counts_on(:tags).order(:name)
  end

  
  # Périmètre de services d'un index. Au premier affichage (filtre non soumis), le
  # filtre est laissé VIDE et on montre tout le périmètre (toute l'organisation pour
  # un admin si `admin_sees_all`, sinon les services du current_user) — sauf l'admin
  # d'un index où il reste scopé à ses services (`admin_sees_all: false`, ex. /users),
  # auquel cas ses services sont présélectionnés. Une fois le filtre soumis : les
  # services demandés (bornés au périmètre), ou tout le périmètre s'il est vidé.
  # Renseigne @services (options du menu) et @selected_service_ids (sélection).
  def scoped_services(param_key, admin_sees_all: false)
    default_services = current_user.services
    allowed_services = (current_user.administrateur? && current_organisation&.services) || default_services
    @services = allowed_services

    # Premier affichage : filtre non soumis.
    unless params.key?(param_key)
      # Admin d'un index « scopé » (ex. /users) : ses services restent présélectionnés.
      if current_user.administrateur? && !admin_sees_all
        @selected_service_ids = default_services.ids
        return default_services
      end
      # Sinon (admin « voit tout », ou manager) : filtre vide, on montre tout le périmètre.
      @selected_service_ids = []
      return allowed_services
    end

    # Filtre soumis : services demandés (bornés au périmètre), ou tout le périmètre
    # autorisé si le filtre a été vidé.
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