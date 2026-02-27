class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager
  end

  def show?
    index?
  end

  def new?
    manager
  end

  def create?
    new?
  end

  def edit?
    manager
  end

  def update?
    edit?
  end

  def destroy?
    manager
  end
end
