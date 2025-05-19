class NewsletterPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user && user.super_admin?
  end

  def create?
    true
  end

  def destroy?
    true
  end
end