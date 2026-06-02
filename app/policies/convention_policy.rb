# frozen_string_literal: true

class ConventionPolicy < ApplicationPolicy
  def create?
    organisation? && (administrateur? || (user.manager? && user.services.include?(record.service)))
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
