class MouvementPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager_or_admin?
  end

  # Page désactivé
  def show?
    false
  end

  def new?
    manager_or_admin?
  end

  def create?
    new?
  end

  # Page désactivé
  def edit?
    manager_or_admin? && organisation?
  end

  # Page désactivé
  def update?
    edit?
  end

  def destroy?
    manager_or_admin? || record.user == user
  end

  def reserve?
    !user.adhérent?
  end
end