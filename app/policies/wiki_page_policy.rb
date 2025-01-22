class WikiPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # def index?
  #   true
  # end

  # def show?
  #   true
  # end

  def new?
    user && user.super_admin?
  end

  def create?
    new?
  end

  def edit?
    user && user.super_admin?
  end

  def update?
    edit?
  end

  def destroy?
    user && user.super_admin?
  end
end