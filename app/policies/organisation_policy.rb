# frozen_string_literal: true

class OrganisationPolicy < ApplicationPolicy
  def show?
    administrateur? && record == user.organisation
  end

  def update?
    show?
  end

  def destroy?
    show?
  end
end
