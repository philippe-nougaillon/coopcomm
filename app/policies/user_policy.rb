class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    manager_or_admin?
  end

  def show?
    (index? && organisation? && shared_service) || record == user
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    show?
  end

  def update?
    edit?
  end

  def destroy?
    manager_or_admin? && organisation? && record != user && shared_service
  end

  def agent_calendrier?
    index?
  end

  def import?
    manager_or_admin?
  end

  def import_do?
    import?
  end

  def inviter?
    manager_or_admin? && organisation? && record != user && shared_service
  end

  def edit_password?
    record == user
  end

  def update_password?
    edit_password?
  end

  def reactivate?
    manager_or_admin? && organisation? && shared_service
  end
end