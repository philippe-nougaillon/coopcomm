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
    edit? && record.user == user
  end
end