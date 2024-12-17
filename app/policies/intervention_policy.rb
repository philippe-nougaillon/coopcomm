class InterventionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def show?
    index? && record.organisation == user.organisation
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
    show? && user.manager?
  end

  def accepter?
    show?
  end

  def en_cours?
    show?
  end

  def terminer?
    show?
  end

  def valider?
    show?
  end

  def refuser?
    show?
  end

  def archiver?
    show?
  end

  def purge?
    show?
  end
end