class OrganisationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def show?
    manager && record == user.organisation
  end

  def edit?
    show?
  end

  def update?
    edit?
  end
end