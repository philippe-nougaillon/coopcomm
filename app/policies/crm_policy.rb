# frozen_string_literal: true

class CrmPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Scope
    end
  end

  def index?
    manager_or_admin? || user.adhérent?
  end
end