# frozen_string_literal: true

# Le catalogue est géré dans la page Paramètres, réservée aux administrateurs.
class PrestationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(organisation: user.organisation)
    end
  end

  def show?
    administrateur? && organisation?
  end
  
  def new?
    administrateur?
  end

  def create?
    new?
  end

  def edit?
    administrateur? && organisation?
  end

  def update?
    edit?
  end

  def destroy?
    administrateur? && organisation?
  end
end
