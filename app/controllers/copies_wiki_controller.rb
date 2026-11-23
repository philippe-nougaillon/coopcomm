# frozen_string_literal: true

class CopiesWikiController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!
  # Appel d'une instance à une autre : l'autorisation est portée par le jeton partagé
  skip_after_action :verify_authorized
  before_action :verifier_jeton

  # GET /copies_wiki/auteurs
  def auteurs
    render json: auteurs_possibles.map { |auteur|
      { email: auteur.email, libellé: [auteur.nom_prenom_role, auteur.organisation&.nom].compact.join(' — ') }
    }
  end

  # POST /copies_wiki
  def create
    données = JSON.parse(request.raw_post)
    auteur = auteurs_possibles.find { |user| user.email == données['auteur'] }
    unless auteur
      return render json: { erreur: 'auteur inconnu, ou pas super_admin manager ou administrateur' },
                    status: :unprocessable_content
    end

    page = ImporterPageWiki.call(données['page'], auteur: auteur, publiée: données['publiée'] == true,
                                                  origine: données['origine'])
    render json: { slug: page.slug }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { erreur: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
  end

  private

  def verifier_jeton
    jeton = ENV['JETON_INSTANCES'].to_s
    return if jeton.present? && ActiveSupport::SecurityUtils.secure_compare(request.authorization.to_s, "Bearer #{jeton}")

    render json: { erreur: 'jeton absent ou refusé' }, status: :unauthorized
  end

  def auteurs_possibles
    User.ordered.select { |user| user.super_admin? && user.manager_or_admin? }
  end
end
