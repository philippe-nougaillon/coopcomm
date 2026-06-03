# frozen_string_literal: true

class CotationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Cotation.visible_to(user)
    end
  end

  def index?
    user && user.manager_or_admin?
  end

  # Ouverture du formulaire (niveau classe) : tout manager/admin.
  def new?
    user && user.manager_or_admin?
  end

  # À l'enregistrement, on vérifie en plus que le service appartient bien
  # à l'utilisateur (sauf admin).
  def create?
    manage?
  end

  def show?
    manage?
  end

  def update?
    manage?
  end

  def destroy?
    manage?
  end

  def pdf?
    show?
  end

  private

  def manage?
    return false unless user

    organisation? && (administrateur? || (user.manager? && user.services.include?(record.service)))
  end
end
