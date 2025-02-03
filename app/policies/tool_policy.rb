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
    index? && record.organisation == user.organisation
  end

  def new?
    user && user.manager?
  end

  def create?
    new?
  end

  def edit?
    user && user.manager?
  end

  def update?
    edit?
  end

  def destroy?
    user && user.manager?
  end
end