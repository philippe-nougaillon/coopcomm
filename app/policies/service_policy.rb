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
    index? && shared_service([record])
  end

  def new?
    manager
  end

  def create?
    new?
  end

  def edit?
    manager && shared_service([record])
  end

  def update?
    edit?
  end

  def destroy?
    manager && shared_service([record])
  end
end
