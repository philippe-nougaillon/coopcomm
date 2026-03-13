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
    false
  end

  # Page désactivé
  def update?
    edit?
  end

  # Page désactivé
  def destroy?
    false
  end
end