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
    index? && organisation
  end

  def new?
    manager
  end

  def create?
    new?
  end

  def edit?
    manager && organisation
  end

  def update?
    edit?
  end

  def destroy?
    manager && organisation
  end
end