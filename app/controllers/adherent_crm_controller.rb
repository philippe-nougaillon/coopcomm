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