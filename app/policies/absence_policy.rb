# frozen_string_literal: true

class AbsencePolicy < ApplicationPolicy
  # Supprimer une absence = pouvoir modifier la fiche de l'utilisateur concerné
  # (les absences se gèrent déjà via absences_attributes du formulaire User).
  def destroy?
    UserPolicy.new(user, record.user).update?
  end
end
