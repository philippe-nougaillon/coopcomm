# frozen_string_literal: true

# Page unique pour l'adhérent : ses Commandes / Factures / Cotations,
# regroupées par onglets (mêmes scopes `visible_to` que les index dédiés,
# donc les brouillons « créé » restent invisibles).
class AdherentCrmController < ApplicationController
  before_action :is_user_authorized

  trie Cotation, defaut: 'cotations.updated_at', sens: :desc
  trie Commande, defaut: 'commandes.updated_at', sens: :desc
  trie Facture, defaut: 'factures.updated_at', sens: :desc

  TABS = %w[cotations commandes factures].freeze

  def index
    @tab = TABS.include?(params[:tab]) ? params[:tab] : 'cotations'

    case @tab
    when 'cotations'
      prepare_variables_of_cotation_for_view
    when 'commandes'
      prepare_variables_of_commande_for_view
    when 'factures'
      prepare_variables_of_facture_for_view
    end
  end

  private

  # Filtre sur ref/intitulé
  def apply_filters(scope, table)
    if params[:search].present?
      scope = scope.where("#{table}.ref ILIKE :s OR #{table}.intitulé ILIKE :s", s: "%#{params[:search]}%")
    end

    if params[:adhérent_ids].present?
      scope = scope.where(adherent_id: params[:adhérent_ids])
    end

    if params[:service_ids].present?
      scope = scope.where(service_id: params[:service_ids])
    end

    if params[:workflow_state].present?
      scope = scope.where("#{table}.workflow_state = ?", params[:workflow_state].to_s.downcase)
    end

    return scope
  end

  def prepare_variables_of_cotation_for_view
    base = policy_scope(Cotation)
             .kept
             .includes(:adherent, :service, :organisation)
             .ordered
    @cotations = apply_filters(base, 'cotations')

    service_ids = base.reorder(nil).distinct.pluck(:service_id)
    @services = Service.where(id: service_ids).ordered

    @pagy, @cotations = pagy(trier(@cotations), items: 10)

    # Dernier mail_log par cotation, en une seule requête (DISTINCT ON, Postgres)
    # pour éviter un N+1 dans l'index.
    @last_mail_logs = MailLog
                        .where(cotation_id: @cotations.map(&:id))
                        .select('DISTINCT ON (cotation_id) *')
                        .order(:cotation_id, created_at: :desc)
                        .index_by(&:cotation_id)
  end

  def prepare_variables_of_commande_for_view
    base = policy_scope(Commande)
             .kept
             .includes(:adherent, :service, :organisation)
             .ordered
    @commandes = apply_filters(base, 'commandes')

    service_ids = base.reorder(nil).distinct.pluck(:service_id)
    @services = Service.where(id: service_ids).ordered

    @pagy, @commandes = pagy(trier(@commandes), items: 10)
  end

  def prepare_variables_of_facture_for_view
    base = policy_scope(Facture)
             .kept
             .includes(:adherent, :service, :organisation)
             .ordered
    @factures = apply_filters(base, 'factures')

    service_ids = base.reorder(nil).distinct.pluck(:service_id)
    @services = Service.where(id: service_ids).ordered

    @pagy, @factures = pagy(trier(@factures), items: 10)
  end

  def is_user_authorized
    authorize(:crm)
  end
end