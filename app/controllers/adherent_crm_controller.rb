# frozen_string_literal: true

# Page unique pour l'adhérent : ses Commandes / Factures / Cotations,
# regroupées par onglets (mêmes scopes `visible_to` que les index dédiés,
# donc les brouillons « créé » restent invisibles).
class AdherentCrmController < ApplicationController
  before_action :is_user_authorized

  TABS = %w[cotations commandes factures].freeze

  def index
    @tab = TABS.include?(params[:tab]) ? params[:tab] : 'cotations'

    case @tab
    when 'cotations'
      @cotations = Cotation.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @cotations = apply_search(@cotations, 'cotations')
      @pagy, @cotations = pagy(@cotations, items: 15)
      @last_mail_logs = MailLog
                          .where(cotation_id: @cotations.map(&:id))
                          .select('DISTINCT ON (cotation_id) *')
                          .order(:cotation_id, created_at: :desc)
                          .index_by(&:cotation_id)
    when 'commandes'
      @commandes = Commande.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @commandes = apply_search(@commandes, 'commandes')
      @pagy, @commandes = pagy(@commandes, items: 15)
    when 'factures'
      @factures = Facture.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @factures = apply_search(@factures, 'factures')
      @pagy, @factures = pagy(@factures, items: 15)
    end
  end

  private

  # Filtre sur ref/intitulé
  def apply_search(scope, table)
    return scope if params[:search].blank?
    scope.where("#{table}.ref ILIKE :s OR #{table}.intitulé ILIKE :s", s: "%#{params[:search]}%")
  end

  def is_user_authorized
    authorize(:crm)
  end
end






# frozen_string_literal: true

# Page unique pour l'adhérent : ses Commandes / Factures / Cotations,
# regroupées par onglets (mêmes scopes `visible_to` que les index dédiés,
# donc les brouillons « créé » restent invisibles).
class AdherentCrmController < ApplicationController
  before_action :is_user_authorized

  TABS = %w[cotations commandes factures].freeze

  def index
    @tab = TABS.include?(params[:tab]) ? params[:tab] : 'cotations'
    @services = Service.order(:nom) # <--- Soluciona el NoMethodError para el select de Services

    case @tab
    when 'cotations'
      @cotations = Cotation.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @cotations = apply_filters(@cotations, 'cotations')
      @pagy, @cotations = pagy(@cotations, items: 15)
      @last_mail_logs = MailLog
                          .where(cotation_id: @cotations.map(&:id))
                          .select('DISTINCT ON (cotation_id) *')
                          .order(:cotation_id, created_at: :desc)
                          .index_by(&:cotation_id)
    when 'commandes'
      @commandes = Commande.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @commandes = apply_filters(@commandes, 'commandes')
      @pagy, @commandes = pagy(@commandes, items: 15)
    when 'factures'
      @factures = Facture.visible_to(current_user).kept.includes(:adherent, :service).ordered
      @factures = apply_filters(@factures, 'factures')
      @pagy, @factures = pagy(@factures, items: 15)
    end
  end

  private

  # Aplica los filtros de búsqueda por texto, servicio y estado
  def apply_filters(scope, table)
    # 1. Filtro por búsqueda de texto (Réf, Intitulé)
    if params[:search].present?
      scope = scope.where("#{table}.ref ILIKE :s OR #{table}.intitulé ILIKE :s", s: "%#{params[:search]}%")
    end

    # 2. Filtro por Servicios seleccionados
    if params[:service_ids].present?
      # Descarta valores vacíos si el select múltiple envía un elemento en blanco
      service_ids = Array(params[:service_ids]).reject(&:blank?)
      scope = scope.where(service_id: service_ids) if service_ids.any?
    end

    # 3. Filtro por Statut (workflow_state)
    if params[:workflow_state].present?
      scope = scope.where(workflow_state: params[:workflow_state])
    end

    scope
  end

  def is_user_authorized
    authorize(:crm)
  end
end