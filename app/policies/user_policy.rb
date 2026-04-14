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
    (index? && can_manage_record?) || is_myself?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    # Un manager ne peut pas modifier un manager ou un administrateur, sauf si c'est lui-même
    show? && (is_myself? || !hierarchy_violation?)
  end

  def update?
    edit?
  end

  def destroy?
    can_manage_record? && !is_myself? && !hierarchy_violation?
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
    can_manage_record? && !is_myself?
  end

  def edit_password?
    is_myself?
  end

  def update_password?
    edit_password?
  end

  def reactivate?
    can_manage_record?
  end

  private

  # Vérifie si l'utilisateur peut manager le record
  def can_manage_record?
    manager_or_admin? && organisation? && shared_service?
  end

  # Vérifie si un manager tente d'agir sur un grade égal ou supérieur
  def hierarchy_violation?
    user.manager? && record.manager_or_admin?
  end

  # Vérifie si le record manipulé est l'utilisateur courant
  def is_myself?
    record == user
  end
end