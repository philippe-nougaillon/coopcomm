class PagesPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def assistant?
    administrateur?
  end

  def dashboard?
    user && (manager_or_admin? || user.adhérent? )
  end

  def home?
    user
  end

  def meteo?
    home?
  end

  def meteo_by_day?
    home?
  end
end