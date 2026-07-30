# frozen_string_literal: true

class AbsencePolicy < ApplicationPolicy
  # Créer, modifier et supprimer une absence sont réservés aux managers et aux
  # administrateurs, y compris sur leur propre fiche.
  def create?
    manager_or_admin? && UserPolicy.new(user, record.user).update?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end
end
