class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager
  end

  def show?
    (index? && organisation) || record == user
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    show?
  end

  def update?
    edit?
  end

  def destroy?
    manager && organisation && record != user
  end

  def agent_calendrier?
    index?
  end
end