class AdminPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def audits?
    user && user.manager?
  end

  def create_new_user?
    user && user.manager?
  end

  def create_new_user_do?
    create_new_user?
  end

  def messagerie?
    user
  end

  def send_notification?
    user
  end

  def stats?
    user && ENV['SUPER_ADMIN'].to_s.split(',').include?(user.email)
  end
end