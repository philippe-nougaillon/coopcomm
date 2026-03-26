class AdminPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def audits?
    manager_or_admin?
  end

  def create_new_user?
    manager_or_admin?
  end

  def create_new_user_do?
    create_new_user?
  end

  def stats?
    user && ENV['SUPER_ADMIN'].to_s.split(',').include?(user.email)
  end
end