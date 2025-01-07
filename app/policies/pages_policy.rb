class PagesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def assistant?
    user && user.manager?
  end

  def dashboard?
    user && (user.manager? || user.adhérent? )
  end
end