# frozen_string_literal: true

class CommandePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager_or_admin?
  end

  # def new?
  #   manager_or_admin?
  # end

  # def create?
  #   manager_or_admin?
  # end

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
end
