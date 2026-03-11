class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    administrateur?
  end

  def show?
    index? && shared_service([record])
  end

  def new?
    administrateur?
  end

  def create?
    new?
  end

  def edit?
    administrateur? && shared_service([record])
  end

  def update?
    edit?
  end

  def destroy?
    administrateur? && shared_service([record])
  end
end
