# frozen_string_literal: true

class ConventionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      Convention.visible_to(user)
    end
  end

  def index?
    user&.manager_or_admin? || adhérent?
  end

  def new?
    user&.manager_or_admin?
  end

  def services_for_adherent?
    new?
  end

  def create?
    new?
  end

  def show?
    return analyste? unless record.validé?

    manage? || (adhérent? && record.user == user)
  end

  def edit?
    record.validé? ? manage? : analyste?
  end

  def update?
    edit?
  end

  def destroy?
    edit?
  end

  def pdf?
    record.validé? && show?
  end

  def analyser?
    manager_or_admin?
  end

  def analyses?
    analyser?
  end

  def relancer?
    analyste?
  end

  # Un manager ne valide que sur ses services : son formulaire ne lui en propose pas d'autre.
  def valider?
    analyste? && (administrateur? || user.services.include?(record.service))
  end

  private

  # Le déposant d'une analyse, ou un administrateur de son organisation.
  def analyste?
    user.present? && (record.deposant == user || (administrateur? && record.organisation_du_deposant == user.organisation))
  end
end
