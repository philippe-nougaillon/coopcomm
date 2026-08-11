# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # def index?
  #   administrateur?
  # end

  def show?
    administrateur? && organisation?
  end

  def new?
    administrateur?
  end

  def create?
    new?
  end

  def edit?
    administrateur? && organisation?
  end

  def update?
    edit?
  end

  def destroy?
    administrateur? && organisation? && record.can_be_destroyed?
  end
end
