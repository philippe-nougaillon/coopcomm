# frozen_string_literal: true

class CommandePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Commande.visible_to(user)
    end
  end

  
  def index?
    user&.manager_or_admin? || adhérent?
  end

  # def new?
  #   manager_or_admin?
  # end

  # def create?
  #   manager_or_admin?
  # end


  # Un adhérent voit le détail de n'importe laquelle de ses commandes,
  # quel que soit son état.
  def show?
    manage? || (adhérent? && record.adherent_id == user.id && !record.créé?)
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

  def create_facture?
    manage? && record.validé?
  end
end

AdherentCommandePolicy = CommandePolicy