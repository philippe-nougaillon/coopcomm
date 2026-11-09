# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && (manager_or_admin? || user.adhérent?)
  end

  def reservations_du_jour?
    user && manager_or_admin?
  end
end
