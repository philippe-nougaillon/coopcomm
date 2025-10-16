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
    index? && organisation
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
    show?
  end

  def agent_calendrier?
    index?
  end

  def enable_otp?
    index?
  end

  def disable_otp?
    index?
  end
end