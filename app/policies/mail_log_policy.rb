class MailLogPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager_or_admin?
  end

  def show?
    index? && organisation?
  end

  def refresh?
    index?
  end
end