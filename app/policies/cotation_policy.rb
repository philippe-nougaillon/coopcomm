# frozen_string_literal: true

class CotationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Cotation.visible_to(user)
    end
  end

  def index?
    user&.manager_or_admin?
  end

  # Ouverture du formulaire (niveau classe) : tout manager/admin.
  def new?
    user&.manager_or_admin?
  end

  # À l'enregistrement, on vérifie en plus que le service appartient bien
  # à l'utilisateur (sauf admin).
  def create?
    manage?
  end

  def show?
    manage?
  end

  # Modification (et edit?, qui en hérite) : réservée aux états modifiables,
  # c.-à-d. tant que la cotation n'a pas été envoyée, ou après un refus.
  def update?
    manage? && record.modifiable?
  end

  def destroy?
    manage?
  end

  def pdf?
    show?
  end

  # Transitions du workflow : réservées à qui peut gérer la cotation
  def envoyer?
    manage?
  end

  def valider?
    manage?
  end

  def refuser?
    manage?
  end

  def create_commande?
    manage?
  end
end
