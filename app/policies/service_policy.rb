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
    index? && organisation?
  end

  def new?
    administrateur?
  end

  def create?
    new?
  end

  def edit?
    administrateur? && organisation?
  end

  def update?
    edit?
  end

  def destroy?
    administrateur? && organisation?
  end
end
