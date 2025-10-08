class PagesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def assistant?
    manager
  end

  def dashboard?
    user && (user.manager? || user.adhérent? )
  end

  def home?
    user
  end
end