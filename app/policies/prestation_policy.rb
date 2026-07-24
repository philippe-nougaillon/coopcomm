# frozen_string_literal: true

# Le catalogue de prestations est géré dans la page Paramètres, réservée aux
# administrateurs (cf. AdminPolicy#parametres?). On aligne donc la gestion des
# prestations sur les administrateurs uniquement, comme pour les services.
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
