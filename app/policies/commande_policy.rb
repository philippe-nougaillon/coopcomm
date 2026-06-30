# frozen_string_literal: true

class CommandePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager_or_admin?
  end

  # def new?
  #   manager_or_admin?
  # end

  def create?
    manager_or_admin?
  end

  def create_from_cotation?
    manager_or_admin?
  end

  def show?
    manager_or_admin?
  end

  # def update?
  #   manage?
  # end

  def destroy?
    manager_or_admin?
  end
end
