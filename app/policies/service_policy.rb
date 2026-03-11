class ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # Pas besoin de vérifier si le service appartient à l'administrateur, comme il a tous les services
  def index?
    administrateur?
  end

  def show?
    index?
  end

  def new?
    administrateur?
  end

  def create?
    new?
  end

  def edit?
    administrateur?
  end

  def update?
    edit?
  end

  def destroy?
    administrateur?
  end
end
