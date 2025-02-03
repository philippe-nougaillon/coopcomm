class MailLogPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.manager?
  end

  def show?
    index? && record.organisation.users.include?(user)
  end

  def refresh?
    index?
  end
end