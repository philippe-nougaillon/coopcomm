class InterventionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def show?
    index? && organisation? && (manager_or_admin? || record.adherent == user || record.agents.include?(user))
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    show? && ( !record.repeter || !user.agent? )
  end

  def update?
    edit?
  end

  def destroy?
    show? && manager_or_admin?
  end

  # def accepter?
  #   show?
  # end

  # def en_cours?
  #   show?
  # end

  def terminer?
    show? && !user.adhérent?
  end

  def valider?
    show? && !user.agent?
  end

  def refuser?
    valider?
  end

  def archiver?
    show?
  end

  def purge?
    show?
  end

  def get_unavailable_elements?
    index?
  end

  def pointer?
    user && record.agents.include?(user)
  end

  def pointage_statut?
    pointer?
  end

  def services_for_adherent?
    new?
  end

  def update_location?
    pointer?
  end

  def new_intervention_pointage?
    manager_or_admin?
  end

  def create_intervention_pointage?
    new_intervention_pointage?
  end
end