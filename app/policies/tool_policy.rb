class ToolPolicy < ApplicationPolicy
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
    manager
  end

  def update?
    edit?
  end

  def destroy?
    manager
  end
end