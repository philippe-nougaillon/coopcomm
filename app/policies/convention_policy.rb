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
    new?
  end

  def show?
    manage? || (adhérent? && record.user == user)
  end

  def edit?
    user&.manager_or_admin?
  end

  def update?
    edit?
  end

  def destroy?
    manage?
  end
end
