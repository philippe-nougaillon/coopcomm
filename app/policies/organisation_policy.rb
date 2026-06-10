# frozen_string_literal: true

class OrganisationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  # Désactivé
  # def show?
  #   manager_or_admin? && record == user.organisation
  # end

  # Désactivé
  # def edit?
  #   show?
  # end

  # Désactivé
  # def update?
  #   edit?
  # end
end
