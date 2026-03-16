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
    index? && record.organisation.users.include?(user)
  end

  def refresh?
    index?
  end
end