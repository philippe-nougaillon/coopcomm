class WikiPagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # def index?
  #   true
  # end

  def show?
    !record.private? || manager_or_admin?
  end

  def new?
    manager_or_admin?
  end

  def create?
    new?
  end

  def edit?
    manager_or_admin?
  end

  def update?
    edit?
  end

  def destroy?
    edit? && record.user == user
  end
end