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

  rate_limit to: 20, within: 1.minute,
             by: -> { request.ip },
             if: -> { devise_controller? }

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

  # Périmètre de services d'un index, avec valeur par défaut pré-filtrée pour les
  # administrateurs. Mutualisé entre les index (interventions, utilisateurs, et à
  # venir). `param_key` est la clé du paramètre de filtre (ex. :service, :services).
  #
  # Effets de bord pour les vues :
  #   @services            → options du menu déroulant : tous les services de
  #                          l'organisation pour un administrateur, sinon les
  #                          services du current_user ;
  #   @selected_service_ids → ids à pré-sélectionner dans le menu.
  #
  # Retourne la relation des services sélectionnés : les services demandés via le
  # param, TOUJOURS bornés au périmètre autorisé (un param forgé hors périmètre
  # est ignoré) ; à défaut, les services du current_user (pré-filtre).
  def scoped_services(param_key)
    default_services = current_user.services
    allowed_services = (current_user.administrateur? && current_organisation&.services) || default_services
    @services = allowed_services

    requested = allowed_services.where(id: params[param_key]) if params[param_key].present?
    selected = requested.presence || default_services
    @selected_service_ids = selected.ids
    selected
  end

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
end
