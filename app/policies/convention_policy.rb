# frozen_string_literal: true

class ConventionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Convention.visible_to(user)
    end
  end

  def index?
    user&.manager_or_admin? || adhérent?
  end

  def new?
    user&.manager_or_admin?
  end

  def services_for_adherent?
    new?
  end

  def create?
    organisation? && (administrateur? || (user.manager? && user.services.include?(record.service)))
  end

  def show?
    create?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
