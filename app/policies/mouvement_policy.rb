class MouvementPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def show?
    index? && organisation?
  end

  def new?
    manager_or_admin?
  end

  def create?
    new?
  end

  def edit?
    manager_or_admin? && organisation?
  end

  def update?
    edit?
  end

  def destroy?
    manager_or_admin? && organisation?
  end
end